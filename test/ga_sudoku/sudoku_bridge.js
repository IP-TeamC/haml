const fs = require("fs");
const path = require("path");
const WebSocket = require("ws");

const logDir = process.argv[2];

const wss = new WebSocket.Server({ port: 8080 });
const LOG_DIR = logDir ? path.resolve(logDir) : __dirname;

if (!fs.existsSync(LOG_DIR)) {
  fs.mkdirSync(LOG_DIR, { recursive: true });
}

console.log("Log-Path: " + LOG_DIR)
console.log("WebSocket running on ws://localhost:8080");

wss.on("connection", (ws) => {
    let history = [];
    let latest = null;
    let current = null;
    let lastSize = 0;
    
    let solution = null;
    let fixedMask = null;
    let currentGridType = null;
    
    let targetFilePath = null;
    let fileWatcher = null;
    let dirWatcher = null;

    ws.on("message", (msg) => {
        const data = JSON.parse(msg);

        if (data.type === "watch_file") {
            startWatchingFile(data.file);
        }

        if (data.type === "stop_watch") {
            cleanupWatchers();
            targetFilePath = null;
        }
    });

    ws.on("close", () => {
        cleanupWatchers();
    });

    function cleanupWatchers() {
        if (targetFilePath && fileWatcher) {
            fs.unwatchFile(targetFilePath, parseLog);
            fileWatcher = null;
        }
        if (dirWatcher) {
            dirWatcher.close();
            dirWatcher = null;
        }
    }

    function startWatchingFile(filename) {
        cleanupWatchers();

        history = [];
        latest = null;
        current = null;
        lastSize = 0;
        solution = null;
        fixedMask = null;
        currentGridType = null;

        targetFilePath = path.join(LOG_DIR, filename);

        const checkAndStart = () => {
            if (fs.existsSync(targetFilePath)) {
                if (dirWatcher) {
                    dirWatcher.close();
                    dirWatcher = null;
                }
                
                // Einmal manuell sofort einlesen
                parseLog();

                // Danach via WatchFile die Datei überwachen
                fs.watchFile(targetFilePath, { interval: 300 }, parseLog);
                fileWatcher = true;
            }
        };

        // Entweder direkt starten, wenn die Datei schon existiert...
        if (fs.existsSync(targetFilePath)) {
            checkAndStart();
        } else {
            // ... oder den Ordner überwachen, bis sie auftaucht.
            dirWatcher = fs.watch(LOG_DIR, (eventType, triggeredFile) => {
                if (triggeredFile === filename) {
                    checkAndStart();
                }
            });
        }
    }

    function parseLog() {
        if (!targetFilePath || !fs.existsSync(targetFilePath)) return;
        const stats = fs.statSync(targetFilePath);
        
        if (stats.size < lastSize) { 
            lastSize = 0; 
            history = []; 
            latest = null; 
            current = null; 
        }
        if (stats.size === lastSize) return;

        const stream = fs.createReadStream(targetFilePath, { start: lastSize, encoding: "utf-8" });
        let buffer = "";
        
        stream.on("data", chunk => buffer += chunk);
        stream.on("end", () => {
            const lines = buffer.split("\n");

            let isFirstParse = (lastSize === 0);

            for (const line of lines) {
                if (!line) continue;

                if (line.includes("[Bridge] Sudoku Solution")) {
                    currentGridType = "solution";
                    solution = [];
                    continue;
                }
                if (line.includes("[GA] Sudoku geladen")) {
                    currentGridType = "mask";
                    fixedMask = [];

                    const timeMatch = line.match(/@(\d+[a-zA-Z]+)/);
                    
                    current = {
                        generation: 0,
                        fitness: null,
                        timestamp: timeMatch ? timeMatch[1] : "",
                        grid: []
                    };
                    continue;
                }

                // Generation Start erkennen
                if (line.includes("[GA] Generation")) {
                    const genMatch = line.match(/Generation\s+(\d+)/);
                    const fitMatch = line.match(/best_fit=(\d+)/);
                    const timeMatch = line.match(/@(\d+[a-zA-Z]+)/);

                    current = {
                        generation: genMatch ? Number(genMatch[1]) : 0,
                        fitness: fitMatch ? Number(fitMatch[1]) : null,
                        time: timeMatch ? timeMatch[1] : "",
                        grid: []
                    };
                    currentGridType = "grid";
                }

                // Grid parsen
                if (line.includes("|") && /\d/.test(line)) {
                    const nums = line.split("|").map(p => p.trim()).filter(Boolean)
                        .map(p => p.split(/\s+/).map(v => v === "." ? 0 : Number(v)).filter(n => !isNaN(n)))
                        .flat();

                    if (nums.length === 9) {
                        if (currentGridType === "solution") {
                            solution.push(nums);
                            if (solution.length === 9) currentGridType = null;

                        } else if (currentGridType === "mask") {
                            fixedMask.push(nums.map(n => n !== 0));
                            current.grid.push(nums);
                            if (fixedMask.length === 9) {
                                currentGridType = null;
                                latest = { type: "grid", ...current, fixedMask };
                                history.push(latest);
                                
                                if (!isFirstParse) ws.send(JSON.stringify(latest));
                                current = null;
                            }
                            
                        } else if (currentGridType === "grid" && current) {
                            current.grid.push(nums);
                            if (current.grid.length === 9) {
                                latest = { type: "grid", ...current, solution, fixedMask };
                                history.push(latest);
                                
                                if (!isFirstParse) ws.send(JSON.stringify(latest));
                                current = null;
                            }
                        }
                    }
                }
            }

            lastSize = stats.size;

            // Wenn es der erste Durchlauf der Datei war, schicken wir ein kompaktes 'init' Paket
            if (isFirstParse) {
                ws.send(JSON.stringify({
                    type: "init",
                    logName: path.parse(targetFilePath).name,
                    history,
                    latest,
                    solution,
                    fixedMask
                }));
            }
        });
    }
});