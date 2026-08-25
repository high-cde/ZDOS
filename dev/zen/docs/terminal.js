// ZEN CLI + Terminal Engine — Browser Edition

function zen_exec(code) {
    const tokens = code.trim().split(/\s+/);
    const stack = [];

    for (let t of tokens) {
        if (!isNaN(t)) {
            stack.push(parseInt(t));
        } else if (t === "+") {
            stack.push(stack.pop() + stack.pop());
        } else if (t === "-") {
            let b = stack.pop(), a = stack.pop();
            stack.push(a - b);
        } else if (t === "*") {
            stack.push(stack.pop() * stack.pop());
        } else if (t === "/") {
            let b = stack.pop(), a = stack.pop();
            stack.push(a / b);
        } else if (t === "print") {
            return stack.pop();
        } else if (t === "help") {
            return "Comandi: + - * / print help info modules";
        } else if (t === "info") {
            return "ZEN Framework v2 — CLI Browser Edition";
        } else if (t === "modules") {
            return "[zvm, zasm, znet, zsec, zboot, zai, zdb, zfs, zui, zos]";
        } else {
            return "Errore: comando sconosciuto '" + t + "'";
        }
    }
    return "(ok)";
}

function zen_terminal_init() {
    const term = document.getElementById("zen-terminal");
    const input = document.getElementById("zen-input");

    input.addEventListener("keydown", e => {
        if (e.key === "Enter") {
            const cmd = input.value;
            input.value = "";

            const result = zen_exec(cmd);
            term.textContent += "\n$ " + cmd + "\n" + result;
            term.scrollTop = term.scrollHeight;
        }
    });
}
