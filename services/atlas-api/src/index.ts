import express, { Request, Response } from "express";
import { env, printConfigSummary } from "./config/env";

const app = express();

app.use(express.json());

app.get("/", (_req: Request, res: Response) => {
  res.status(200).json({
    message: `${env.appName} is running`,
    appEnvironment: env.appEnv,
    nodeEnvironment: env.nodeEnv,
    apiVersion: env.apiVersion,
    configSource: env.configSource
  });
});

app.get("/health", (_req: Request, res: Response) => {
  res.status(200).json({
    status: "ok",
    service: env.appName
  });
});

app.get("/ready", (_req: Request, res: Response) => {
  res.status(200).json({
    status: "ready",
    service: env.appName,
    databaseConfigured: Boolean(env.databaseUrl)
  });
});

printConfigSummary();

app.listen(env.port, () => {
  console.log(`${env.appName} running on port ${env.port}`);
});
