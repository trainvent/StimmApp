"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getBrandRuntimeConfig = getBrandRuntimeConfig;
const VIVOT_PROJECTS = new Set([
    "vivot-prod",
]);
function getBrandRuntimeConfig(projectId = process.env.GCLOUD_PROJECT) {
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
//# sourceMappingURL=brand.js.map