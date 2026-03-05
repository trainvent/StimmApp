type BrandRuntimeConfig = {
  appName: string;
  teamName: string;
  locale: "de" | "en";
};

const VIVOT_PROJECTS = new Set([
  "vivot-prod",
]);

export function getBrandRuntimeConfig(projectId = process.env.GCLOUD_PROJECT): BrandRuntimeConfig {
  if (projectId && VIVOT_PROJECTS.has(projectId)) {
    return {
      appName: "Vivot",
      teamName: "Vivot Team",
      locale: "en",
    };
  }

  return {
    appName: "StimmApp",
    teamName: "StimmApp Team",
    locale: "de",
  };
}
