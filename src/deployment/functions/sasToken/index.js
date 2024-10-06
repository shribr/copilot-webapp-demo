const { BlobServiceClient, generateBlobSASQueryParameters, StorageSharedKeyCredential } = require('@azure/storage-blob');

module.exports = async function generateSasToken(context, req) {
    const accountName = process.env.AZURE_ACCOUNT_NAME;
    const accountKey = process.env.AZURE_ACCOUNT_KEY;
    const containerName = process.env.AZURE_CONTAINER_NAME;

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
};