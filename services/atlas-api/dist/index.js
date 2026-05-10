"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const app = (0, express_1.default)();
const PORT = process.env.PORT || "3303";
const ENVIRONMENT = process.env.NODE_ENV || "development";
app.use(express_1.default.json());
app.get("/", (_req, res) => {
    res.status(200).json({
        message: "Atlas API is running",
        environment: ENVIRONMENT
    });
});
app.get("/health", (_req, res) => {
    res.status(200).json({
        status: "ok",
        service: "atlas-api"
    });
});
app.get("/ready", (_req, res) => {
    res.status(200).json({
        status: "ready",
        service: "atlas-api"
    });
});
app.listen(Number(PORT), () => {
    console.log(`Atlas API running on port ${PORT}`);
});
