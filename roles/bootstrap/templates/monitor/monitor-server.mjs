import { createServer } from "http"
import { execSync } from "child_process"
import configuration from "./monitor-config.json" assert { type: "json" }

const services = configuration.applications

function getRemainingDiskSpace() {
  const command = "df | grep /$ | tr -s ' ' | cut -d ' ' -f 5 | tr -d '%'"
  try {
    return execSync(command).toString().trim()
  } catch (error) {
    console.error("An error occurred:", error)
    return "-"
  }
}

async function fetchURLStatus(url) {
  try {
    const response = await fetch(url)
    return await response.status
  } catch (error) {
    console.error(`Error fetching ${url}:`, error)
    return 0
  }
}

const port = 8887
createServer(async (req, res) => {
  const result = {
    remainingDiskPercentage: await getRemainingDiskSpace(),
    services: [],
  }
  for (const {
    name,
    domain,
    https,
    node_server_port,
    openfisca_server_port,
  } of services) {
    const localUrl = `http://127.0.0.1:${node_server_port}`
    const serviceUrl = `http${https ? "s" : ""}://${domain}`
    const openfiscaUrl = `http://127.0.0.1:${openfisca_server_port}`

    result.services.push({
      service: `${name} (local)`,
      method: "GET",
      url: localUrl,
      status: await fetchURLStatus(localUrl),
    })
    result.services.push({
      service: name,
      method: "GET",
      url: serviceUrl,
      status: await fetchURLStatus(serviceUrl),
    })
    result.services.push({
      service: `openfisca_${name} (local)`,
      method: "GET",
      url: openfiscaUrl,
      status: await fetchURLStatus(openfiscaUrl),
    })
  }
  res.writeHead(200, {
    "Content-Type": "application/json",
  })
  res.write(JSON.stringify(result, null, 2))
  res.end()
}).listen(port)
