exports.sendToChat = function sendToChat (req, res) {
  console.log("body: "+  req.body)
  var uri = process.env.CHAT_URL;
 
  var body = {
    "cards":[
      {
        "header":{
          "title":"Stackdriver Monitoring Alert"
        },
        "sections":[
          {
            "widgets":[
              {
                "keyValue":{
                  "topLabel":"Summary",
                  "content":req.body.incident.summary,
                  "contentMultiline":"true"
                }
              },
              {
                "keyValue":{
                  "topLabel":"state",
                  "content":req.body.incident.state,
                  "contentMultiline":"false"
                }
              },
              {
                "keyValue":{
                  "topLabel":"Policy",
                  "content":req.body.incident.policy_name
                }
              },
              {
                "keyValue":{
                  "topLabel":"Condition",
                  "content":req.body.incident.condition_name
                }
              },
              {
                "keyValue":{
                  "topLabel":"Resource",
                  "content":req.body.incident.resource_name + "   (" + req.body.incident.resource_id + ")"
                }
              }
            ]
          },
          {
            "widgets":[
              {
                "buttons":[
                  {
                    "textButton":{
                      "text":"Show in Console",
                      "onClick":{
                        "openLink":{
                          "url":req.body.incident.url
                        }
                      }
                    }
                  }
                ]
              }
            ]
          }
        ]
      }
    ]
  };

  const axios = require('axios');  	

  axios.post(uri,body);    
};