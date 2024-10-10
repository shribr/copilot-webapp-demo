const fs = require('fs');

// Read the JSON file
const data = fs.readFileSync('config.json', 'utf8');
const jsonData = JSON.parse(data);

// Query the AI_REQUEST_BODY
const aiRequestBody = jsonData.AI_REQUEST_BODY;
aiRequestBody.messages[0].content = "Hello, World!";
console.log(aiRequestBody);