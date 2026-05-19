const fs = require("fs");
const path = require("path");
const WebSocket = require("ws");

let input = process.argv[2];

if (!input) {
    input = "sim.log"
}

if (!input.toLowerCase().endsWith(".log")) {
    input += ".log";
}

const logPath = path.join(__dirname, input);
console.log("LOG PATH:", logPath);

const wss = new WebSocket.Server({ port: 8080 });
console.log("WebSocket running on ws://localhost:8080");

// --------------------
// STATE
// --------------------
let history = [];
let latest = null;
let lastGeneration = null;
let current = null;
let lastSize = 0;

// Start parsing on boot
parseLog();

// --------------------
// PARSER
// --------------------
function parseLog() {

    if (!fs.existsSync(logPath)) return;

    const stats = fs.statSync(logPath);

    // file got truncated or rotated
    if (stats.size < lastSize) {
        lastSize = 0;
        history = [];
        latest = null;
        current = null;
        lastGeneration = null;
    }

    if (stats.size === lastSize) return;

    const stream = fs.createReadStream(logPath, {
        start: lastSize,
        encoding: "utf-8"
    });

    let buffer = "";

    stream.on("data", chunk => {
        buffer += chunk;
    });

    stream.on("end", () => {

        const lines = buffer.split("\n");

        for (const line of lines) {
            if (!line) continue;

            // --------------------
            // GENERATION
            // --------------------
            if (line.includes("[ctrl] Generation")) {

                const genMatch = line.match(/Generation\s+(\d+)/);
                const fitMatch = line.match(/best_fit=(\d+)/);

                const gen = genMatch ? Number(genMatch[1]) : null;

                if (gen !== lastGeneration) {
                    lastGeneration = gen;

                    current = {
                        generation: gen,
                        fitness: fitMatch ? Number(fitMatch[1]) : null,
                        grid: []
                    };
                }
            }

            // --------------------
            // GRID
            // --------------------
            if (current && line.includes("|") && /\d/.test(line)) {

                const nums = line
                    .split("|")
                    .map(p => p.trim())
                    .filter(Boolean)
                    .map(p =>
                        p.split(/\s+/)
                            .map(v => v === "." ? 0 : Number(v))
                            .filter(n => !isNaN(n))
                    )
                    .flat();

                if (nums.length === 9) {
                    current.grid.push(nums);
                }

                if (current.grid.length === 9) {

                    const snapshot = {
                        type: "grid",
                        ...current
                    };

                    latest = snapshot;
                    history.push(snapshot);

                    broadcast(snapshot);
                    current = null;
                }
            }
        }

        lastSize = stats.size;
    });
}

// --------------------
// WATCH FILE
// --------------------
fs.watchFile(logPath, { interval: 300 }, () => {
    parseLog();
});

// --------------------
// WS
// --------------------
wss.on("connection", (ws) => {

    console.log("Client connected");

    ws.on("message", (msg) => {
        const data = JSON.parse(msg);

        if (data.type === "init") {

            ws.send(JSON.stringify({
                type: "init",
                history,
                latest
            }));
        }
    });
});

// --------------------
// BROADCAST (nur latest)
// --------------------
function broadcast(data) {

    const msg = JSON.stringify(data);

    wss.clients.forEach(c => {
        if (c.readyState === WebSocket.OPEN) {
            c.send(msg);
        }
    });
}