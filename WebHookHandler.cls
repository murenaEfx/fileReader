@RestResource(urlMapping='/api/invokeWebhook/*')
global with sharing class WebHookHandler {

    @HttpPost
    global static void handlePost() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        // 1. Get the signature from the header (sent by the webhook provider)
        // The signature is usually Base64 encoded.
        String receivedSignatureBase64 = req.headers.get('X-Webhook-Signature');
        
        // 2. Get the raw request body
        Blob requestBody = req.requestBody;

        // --- SECURITY BEST PRACTICE ---
        // 3. Retrieve your secret key. 
        // NEVER hardcode a secret key in your code. 
        // Store it in a Protected Custom Setting or Custom Metadata Type for security and manageability.
        // For this example, we'll define it as a string and convert it to a Blob.
        String secret = 'YOUR_SUPER_SECRET_AND_LONG_KEY'; // <-- Replace with key from secure storage
        Blob secretKey = Blob.valueOf(secret);
        // ---

        // 4. Validate the input
        if (String.isBlank(receivedSignatureBase64)) {
            res.statusCode = 401;
            res.responseBody = Blob.valueOf('Unauthorized: Missing signature header.');
            return;
        }

        // 5. Use Crypto.verifyMac to securely compare the received signature 
        // with a signature you generate on your end. This method is constant-time
        // to prevent timing attacks.
        // The method requires the received signature to be a Blob, so we decode it from Base64.
        try {
            Blob receivedSignatureBlob = EncodingUtil.base64Decode(receivedSignatureBase64);
            
            if (Crypto.verifyMac('HMACSHA256', requestBody, secretKey, receivedSignatureBlob)) {
                
                // --- SIGNATURE IS VALID ---
                System.debug('Webhook authenticated successfully. Processing payload...');
                String payloadString = requestBody.toString();
                System.debug('Payload: ' + payloadString);

                // Add your business logic here to process the payloadString
                
                res.statusCode = 200; // OK
                res.responseBody = Blob.valueOf('Webhook Received and Authenticated.');

            } else {
                
                // --- SIGNATURE IS INVALID ---
                System.debug('Webhook authentication failed. Invalid signature.');
                res.statusCode = 401; // Unauthorized
                res.responseBody = Blob.valueOf('Unauthorized: Invalid signature.');
            }
        } catch (Exception e) {
            // This catches errors like an invalid Base64 string in the header.
            System.debug('Error during webhook validation: ' + e.getMessage());
            res.statusCode = 400; // Bad Request
            res.responseBody = Blob.valueOf('Bad Request: Could not decode signature.');
        }

        //TEST
        //TEST
        //TEST
        //TEST
        //TEST
        //TEST
    }
}