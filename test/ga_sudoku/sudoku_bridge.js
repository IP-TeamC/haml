const fs = require("fs");
const path = require("path");
const WebSocket = require("ws");

let input = process.argv[2] || "sim.log";
if (!input.toLowerCase().endsWith(".log")) input += ".log";

const logPath = path.join(__dirname, input);
console.log("LOG PATH:", logPath);

const wss = new WebSocket.Server({ port: 8080 });
console.log("WebSocket running on ws://localhost:8080");

let history = [];
let latest = null;
let lastGeneration = null;
let current = null;
let lastSize = 0;

let solution = null;
let fixedMask = null;
let currentGridType = null;

parseLog();

function parseLog() {
    if (!fs.existsSync(logPath)) return;
    const stats = fs.statSync(logPath);
    if (stats.size < lastSize) { lastSize = 0; history = []; latest = null; current = null; }
    if (stats.size === lastSize) return;

    const stream = fs.createReadStream(logPath, { start: lastSize, encoding: "utf-8" });
    let buffer = "";
    stream.on("data", chunk => buffer += chunk);
    stream.on("end", () => {
        const lines = buffer.split("\n");

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
                        if (fixedMask.length === 9) currentGridType = null;
                    } else if (currentGridType === "grid" && current) {
                        current.grid.push(nums);
                        if (current.grid.length === 9) {
                            latest = { type: "grid", ...current, solution, fixedMask };
                            history.push(latest);
                            broadcast(latest);
                            current = null;
                        }
                    }
                }
            }
        }
        lastSize = stats.size;
    });
}

fs.watchFile(logPath, { interval: 300 }, parseLog);

wss.on("connection", (ws) => {
    ws.on("message", (msg) => {
        const data = JSON.parse(msg);
        if (data.type === "init") {
            ws.send(JSON.stringify({
                type: "init",
                logName: path.parse(logPath).name,
                history,
                latest,
                solution,
                fixedMask
            }));
        }
    });
});

function broadcast(data) {
    const msg = JSON.stringify(data);
    wss.clients.forEach(c => { if (c.readyState === WebSocket.OPEN) c.send(msg); });
}