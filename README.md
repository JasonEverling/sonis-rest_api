## Jenzabar Sonis RESTful API Addon
An addon for Sonis that allows a Restful type experience using JSON to send and receive. New functions added as well as the built-in Sonis functions can be called.

#### Installation
Copy everything in the src/ folder to your Sonis directory. It will ask about folder merge because we are adding content to the Sonis /common folder.

Create a new Sonis API security user, the username NEEDS to start with api of course, for example, apiuser2.

#### Usage
Works with builtin Sonis components!

Create JSON payload,

#### Required:  
Header: X-SONIS-AUTHN: your api users token  
Data/JSON:
- object: the components name
- method: the method being called
- returns: true if data returned, false if boolean function
- builtin: true if using Sonis builtin function or false if using a custom component from this plugin
- argumentdata: a simple array of properties:value pairs for the component and function being called. Check the documentation for each component to fund out what is required.

#### Examples
The below are using curl but you can also use Postman (https://www.getpostman.com/) and the likes  

Example using custom component/method
````
curl -X POST https://sonis.example.com/rest.cfm \
    -H "Content-Type: application/json" \
    -H "X-SONIS-AUTHN: your api users token" \
    -d '{"object": "person","method": "getDetails","returns": true,"builtin": false,"argumentdata": {"user": "000000000","type": "soc_sec"}}'
````

Example using builtin component/method 
````
curl -X POST https://sonis.example.com/rest.cfm \
    -H "Content-Type: application/json" \
    -H "X-SONIS-AUTHN: your api users token" \
    -d '{"object": "address","method": "addressSearch","returns": true,"builtin": true,"argumentdata": {"soc_sec": "000000000","preferred": true}}'
````

#### Screenshot
![Example Screenshot](sample.png?raw=true?v=1 "Example Screenshot")
