require('dotenv').config()
const { readFileSync, writeFileSync } = require('fs')
const uuid = require('uuid')

const apmTemplate = readFileSync('./data/apm.template', 'utf-8')
const compTemplate = readFileSync('./data/component.template', 'utf-8')
const script = readFileSync('./data/o365-status.ps1', 'utf-8')
const services = JSON.parse(readFileSync('./data/o365-services.json', 'utf-8'))

const tenantId = process.env.TENANT_ID || '&lt;Tenant-ID&gt;'
const outputFile = process.env.OUTPUT_PATH || 'Office 365 Service Health Status.apm-template'
const includeAdvisory = process.env.INCLUDE_ADVISORY || 'false'
const templateId = 500
const idOffset = 6000
let columnId = 8000
const getNextColId = () => columnId = columnId + 1

console.log('Starting...')

const components = services.map((service, i) => {
  let component = compTemplate.replace(/\{\{COMP_NAME\}\}/g, service.DisplayName)
  component = component.replace(/\{\{COMP_ORDER\}\}/g, i + 1)
  component = component.replace(/\{\{COMP_ID\}\}/g, i + idOffset)
  component = component.replace(/\{\{COMP_SERVICE\}\}/g, service.Id)
  component = component.replace(/\{\{COMP_TENANT_ID\}\}/g, tenantId)
  component = component.replace(/\{\{COMP_INCLUDE_ADVISORY\}\}/g, includeAdvisory)
  component = component.replace(/\{\{COMP_SCRIPT\}\}/g, script)
  component = component.replace(/\{\{COMP_COL_ID\}\}/g, getNextColId())
  component = component.replace(/\{\{COMP_COL_ID2\}\}/g, getNextColId())
  component = component.replace(/\{\{COMP_UNIQUE_ID\}\}/g, uuid.v4())
  return component
})

console.log(`Generated ${components.length} components..`)

let apm = apmTemplate.replace(/\{\{APP_COMPS\}\}/g, components.join('\n'))
apm = apm.replace(/\{\{APP_ID\}\}/g, templateId)
apm = apm.replace(/\{\{APP_UNIQUE_ID\}\}/g, uuid.v4())
apm = apm.replace(/\{\{DATE\}\}/g, (new Date()).toISOString())

console.log('Generated APM template..')
console.log(`Writing to file "${outputFile}"..`)

writeFileSync(outputFile, apm)

console.log('Done!')
