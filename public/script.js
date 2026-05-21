const display = document.getElementById("display");
const history = document.getElementById("history");
const buttons = document.querySelectorAll(".btn");

const backendUrl = window.APP_CONFIG?.BACKEND_URL || "http://localhost:8000";

let currentValue = "0";
let firstOperand = null;
let selectedOperation = null;
let waitingForSecondOperand = false;

function updateDisplay() {
    display.value = currentValue;
}

function updateHistory(text) {
    history.textContent = text;
}

function inputNumber(number) {
    if (waitingForSecondOperand) {
        currentValue = number;
        waitingForSecondOperand = false;
        return;
    }
    currentValue = currentValue === "0" ? number : currentValue + number;
}

function inputDecimal() {
    if (waitingForSecondOperand) {
        currentValue = "0.";
        waitingForSecondOperand = false;
        return;
    }
    if (!currentValue.includes(".")) {
        currentValue += ".";
    }
}

function clearCalculator() {
    currentValue = "0";
    firstOperand = null;
    selectedOperation = null;
    waitingForSecondOperand = false;
    updateHistory("Aucune opération");
}

function deleteLast() {
    if (waitingForSecondOperand) return;
    currentValue = currentValue.length > 1 ? currentValue.slice(0, -1) : "0";
}

function toggleSign() {
    if (currentValue === "0") return;
    currentValue = String(Number(currentValue) * -1);
}

function chooseOperation(operation) {
    firstOperand = currentValue;
    selectedOperation = operation;
    waitingForSecondOperand = true;
    updateHistory(`${firstOperand} ${operation}`);
}

async function callBackend() {
    if (!selectedOperation || firstOperand === null || waitingForSecondOperand) {
        return;
    }
    const params = new URLSearchParams({
        operation: selectedOperation,
        a: firstOperand,
        b: currentValue
    });
    try {
        const response = await fetch(`${backendUrl}/calculate?${params.toString()}`);
        const data = await response.json();
        if (!response.ok || data.error) {
            throw new Error(data.error || "Erreur backend");
        }
        updateHistory(`${firstOperand} ${selectedOperation} ${currentValue} =`);
        currentValue = String(data.result);
        firstOperand = null;
        selectedOperation = null;
        waitingForSecondOperand = false;
        updateDisplay();
    } catch (error) {
        currentValue = "Erreur";
        updateHistory(error.message);
        firstOperand = null;
        selectedOperation = null;
        waitingForSecondOperand = false;
        updateDisplay();
    }
}

buttons.forEach((button) => {
    button.addEventListener("click", async () => {
        const action = button.dataset.action;
        const value = button.dataset.value;
        switch (action) {
            case "number":   inputNumber(value); updateDisplay(); break;
            case "decimal":  inputDecimal(); updateDisplay(); break;
            case "clear":    clearCalculator(); updateDisplay(); break;
            case "delete":   deleteLast(); updateDisplay(); break;
            case "sign":     toggleSign(); updateDisplay(); break;
            case "operator": chooseOperation(value); break;
            case "equal":    await callBackend(); break;
        }
    });
});

document.addEventListener("keydown", async (event) => {
    if (/^[0-9]$/.test(event.key)) { inputNumber(event.key); updateDisplay(); }
    else if (event.key === ".") { inputDecimal(); updateDisplay(); }
    else if (event.key === "+") chooseOperation("add");
    else if (event.key === "-") chooseOperation("subtract");
    else if (event.key === "*") chooseOperation("multiply");
    else if (event.key === "/") chooseOperation("divide");
    else if (event.key === "Enter" || event.key === "=") { event.preventDefault(); await callBackend(); }
    else if (event.key === "Backspace") { deleteLast(); updateDisplay(); }
    else if (event.key === "Escape") { clearCalculator(); updateDisplay(); }
});

updateDisplay();