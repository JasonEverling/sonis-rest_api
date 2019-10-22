## Jenzabar Sonis RESTful API Addon
An addon for Sonis that allows a Restful type experience using JSON to send and receive. New functions added as well as the built-in Sonis functions can be called.

###### Note: This will also update the soapsql and soapapi components with an improved version for backward compatibility with older clients that only support SOAP.
#### Installation
Copy everything in the src/ folder to your Sonis directory. If it asks about a folder merge, click yes.

Login to the web interface of Sonis, then create a new Sonis API security user.

#### Usage
Works with builtin Sonis components!

Create JSON payload,

##### Required:  
Header: X-SONIS-USER: your api username  
Header: X-SONIS-PWD: your api password  
Data/JSON:
- object: the components name
- action: the method being called
- returns: true if data returned, false if boolean function
- builtin: true if using Sonis builtin function or false if using a custom component from this plugin
- argumentdata: a simple array of properties:value pairs for the component and function being called. Check the documentation for each component to fund out what is required.

#### Examples
The below are using curl but you can also use Postman (https://www.getpostman.com/) and the likes  

Example using custom component/method
````
curl -X POST https://sonis.example.com/cfc/restapi.cfc?method=v1 \
    -H "Content-Type: application/json" \
    -H "X-SONIS-USER: your api username" \
    -H "X-SONIS-PWD: your api users password" \
    -d '{"object": "person","action": "getPersonAttributes","returns": true,"builtin": false,"argumentdata": {"user": "000000000","type": "soc_sec"}}'
````

Example using builtin component/method 
````
curl -X POST https://sonis.example.com/cfc/restapi.cfc?method=v1 \
    -H "Content-Type: application/json" \
    -H "X-SONIS-USER: your api username" \
    -H "X-SONIS-PWD: your api users password" \
    -d '{"object": "address","action": "addressSearch","returns": true,"builtin": true,"argumentdata": {"soc_sec": "000000000","preferred": true}}'
````

GET Request example, you still need to add the Headers! Also remember, a GET request will store the request URL in your web servers logs so do not use GET to pass sensitive information.
````
https://sonis.example.com/cfc/restapi.cfm?method=v1&object=person&action=getDetails&returns=true&builtin=false&argumentdata=user=000000000;type=soc_sec
````

#### Screenshot
![Example Screenshot](screenshot.png?raw=true?v=1 "Example Screenshot")
