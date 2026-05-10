import dotenv from "dotenv";

const isKubernetes = process.env.KUBERNETES_SERVICE_HOST !== undefined;

if (!isKubernetes) {
  dotenv.config({
    path: ".env.local"
  });
}

export type NodeEnvironment = "development" | "staging" | "production";
export type AppEnvironment = "local" | "dev" | "staging" | "prod";

const requiredEnv = (key: string): string => {
  const value = process.env[key];

  if (!value) {
    const source = isKubernetes ? "Kubernetes ConfigMap/Secret" : ".env.local";

    throw new Error(
      `Missing required environment variable: ${key}. Expected it from ${source}.`
    );
  }

  return value;
};

export const env = {
  isKubernetes,
  configSource: isKubernetes ? "kubernetes" : ".env.local",

  port: Number(process.env.PORT || 3303),
  nodeEnv: requiredEnv("NODE_ENV") as NodeEnvironment,
  appEnv: requiredEnv("APP_ENV") as AppEnvironment,
  appName: requiredEnv("APP_NAME"),
  apiVersion: requiredEnv("API_VERSION"),

  databaseUrl: process.env.DATABASE_URL || ""
};

export const printConfigSummary = (): void => {
  console.log("Atlas API configuration loaded");
  console.log(`Config source: ${env.configSource}`);
  console.log(`App name: ${env.appName}`);
  console.log(`Node environment: ${env.nodeEnv}`);
  console.log(`App environment: ${env.appEnv}`);
  console.log(`API version: ${env.apiVersion}`);
  console.log(`Port: ${env.port}`);

  if (!env.databaseUrl) {
    console.warn("DATABASE_URL is not set. Database features will be disabled.");
  }
};
