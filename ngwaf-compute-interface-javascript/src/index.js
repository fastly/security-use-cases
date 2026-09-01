/// <reference types="@fastly/js-compute" />

import { inspect } from "fastly:security";
import { ConfigStore } from "fastly:config-store";
import { env } from "fastly:env";

/**
 * Perform WAF inspection on the incoming request.
 * Returns the inspection response from NGWAF.
 *
 * @param {Request} req
 * @returns {import('fastly:security').InspectResponse}
 */
function doWafInspection(req) {
  const ngwafConfig = new ConfigStore("ngwaf");
  const corpName = ngwafConfig.get("corp");
  const wsName = ngwafConfig.get("workspace");

  if (!corpName) {
    throw new Error("no `corp` present in config");
  }
  if (!wsName) {
    throw new Error("no `workspace` present in config");
  }

  /** @type {import('@fastly/js-compute').InspectConfig} */
  const config = {
    corp: corpName,
    workspace: wsName,
  };

  // Use the x-source-ip header as the client IP if present and valid
  const sourceIp = req.headers.get("x-source-ip");
  if (sourceIp) {
    config.overrideClientIp = sourceIp;
  }

  return inspect(req, config);
}

/**
 * Format inspection results into a header-friendly string.
 *
 * @param {import('fastly:security').InspectResponse} inspectResp
 * @param {string} clientReqId
 * @returns {string}
 */
function formatWafInspectionHeader(inspectResp, clientReqId) {
  console.log("Inspection Response:", JSON.stringify(inspectResp));

  const tags = inspectResp.tags.join(",");
  return (
    `agentResponse=${inspectResp.waf_response};` +
    ` tags=${tags};` +
    ` decisionms=${inspectResp.decision_ms};` +
    ` requestid=${clientReqId}`
  );
}

/**
 * Perform NGWAF inspection and return a Response.
 *
 * @param {Request} req
 * @returns {Response}
 */
function wafInspectAndRespond(req) {
  // Clone headers so we can attach metadata before inspection
  const headers = new Headers(req.headers);
  headers.set("inspected-by", "compute");
  headers.set("compute-version", env("FASTLY_SERVICE_VERSION"));

  const inspectedReq = new Request(req, { headers });

  const wafInspectionResp = doWafInspection(inspectedReq);

  console.log(JSON.stringify(wafInspectionResp));
  const clientReqId = env("FASTLY_TRACE_ID");
  console.log("Client Request ID:", clientReqId);

  const jsonBody = JSON.stringify({
    decisionms: wafInspectionResp.decision_ms,
    requestid: clientReqId,
    agentResponse: wafInspectionResp.waf_response,
    tags: wafInspectionResp.tags,
    verdict: wafInspectionResp.verdict,
  });

  const status = wafInspectionResp.waf_response;
  const statusCode = status >= 200 && status < 500 ? status : 500;

  return new Response(jsonBody, {
    status: statusCode,
    headers: {
      "waf-info": formatWafInspectionHeader(wafInspectionResp, clientReqId),
      "compute-version": env("FASTLY_SERVICE_VERSION"),
      "Content-Type": "application/json",
    },
  });
}

addEventListener("fetch", (event) => {
  const req = event.request;

  // Reject requests where cdn-secret header is missing or not equal to "foo"
  const cdnSecret = req.headers.get("cdn-secret");
  if (cdnSecret !== "foo") {
    event.respondWith(new Response("Forbidden", { status: 403 }));
    return;
  }

  try {
    event.respondWith(wafInspectAndRespond(req));
  } catch (e) {
    console.error("WAF inspection error:", e);
    event.respondWith(new Response("Internal Server Error", { status: 500 }));
  }
});
