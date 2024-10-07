const { BlobServiceClient, generateBlobSASQueryParameters, StorageSharedKeyCredential } = require('@azure/storage-blob');
const env = require('dotenv').config();

module.exports = async function generateSasToken(context, req) {
    try {
        const accountName = process.env.AZURE_ACCOUNT_NAME;
        const accountKey = process.env.AZURE_ACCOUNT_KEY;
        const containerName = process.env.AZURE_CONTAINER_NAME;

        if (!accountName || !accountKey || !containerName) {
            throw new Error("Missing environment variables");
        }

        const sharedKeyCredential = new StorageSharedKeyCredential(accountName, accountKey);
        const sasOptions = {
            containerName,
            permissions: 'racwdl',
            expiresOn: new Date(new Date().valueOf() + 3600 * 1000) // 1 hour expiry
        };
        const sasToken = generateBlobSASQueryParameters(sasOptions, sharedKeyCredential).toString();

        context.res = {
            body: { sasToken }
        };
    } catch (error) {
        context.log.error("Error generating SAS token:", error);
        context.res = {
            status: 500,
            body: { error: "Internal Server Error" }
        };
    }
};