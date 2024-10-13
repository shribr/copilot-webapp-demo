const fetch = require('node-fetch');

module.exports = async function (context, req) {
    context.log('Azure Function triggered.');

    try {
        const userInput = req.query.q || (req.body && req.body.q);
        if (!userInput) {
            context.log('No user input provided.');
            context.res = {
                status: 400,
                body: "Please pass a query in the request"
            };
            return;
        }

        const apiKey = process.env.AZURE_SEARCH_API_KEY;
        const searchServiceName = process.env.AZURE_SEARCH_SERVICE_NAME;
        const indexName = process.env.AZURE_SEARCH_INDEX;
        const endpoint = `https://${searchServiceName}.search.windows.net/indexes/${indexName}/docs/search?api-version=2020-06-30`;

        context.log(`Endpoint: ${endpoint}`);
        context.log(`Search Query: ${JSON.stringify({ search: userInput, top: 5 })}`);

        const response = await fetch(endpoint, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'api-key': apiKey
            },
            body: JSON.stringify({ search: userInput, top: 5 })
        });

        if (!response.ok) {
            context.log(`HTTP error! status: ${response.status}`);
            throw new Error(`HTTP error! status: ${response.status}`);
        }

        const data = await response.json();
        context.log('Data fetched successfully.');

        context.res = {
            status: 200,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            body: data
        };
    } catch (error) {
        context.log.error('Error fetching data:', error);
        context.res = {
            status: 500,
            body: `Internal Server Error: ${error.message}`
        };
    }
};