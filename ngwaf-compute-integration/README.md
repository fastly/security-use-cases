# Next-Gen WAF in Compute

Pass requests to Fastly's Next-Gen Web Application Firewall (Next-Gen WAF) from Compute code and make decisions based on the WAF analysis response.

This implementation is inspired by the following documentation.
https://www.fastly.com/documentation/solutions/tutorials/next-gen-waf-compute/

Do not forget to link your NGWAF edge deployment instance to the Compute service.
```
curl -X PUT "https://dashboard.signalsciences.net/api/v0/corps/${corpName}/sites/${siteName}/edgeDeployment" \
-H "x-api-user:${SIGSCI_EMAIL}" \
-H "x-api-token:${SIGSCI_TOKEN}" \
-H "Fastly-Key: ${FASTLY_KEY}" \
-H "Content-Type: application/json" \
-d '{"authorizedServices": [ "${fastlySID}" ] }'
```

Check the linked service with the following command.
```
curl -H "x-api-user:${SIGSCI_EMAIL}" -H "x-api-token:${SIGSCI_TOKEN}" \
-H "Content-Type: application/json" \
"https://dashboard.signalsciences.net/api/v0/corps/${corpName}/sites/${siteName}/edgeDeployment"
```
