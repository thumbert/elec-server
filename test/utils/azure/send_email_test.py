import os
import base64
import requests
from ms_graph import generate_access_token

# def draft_attachment(file_path):
#     if not os.path.exists(file_path):
#         print('file is not found')
#         return
#
#     with open(file_path, 'rb') as upload:
#         media_content = base64.b64encode(upload.read())
#
#     data_body = {
#         '@odata.type': '#microsoft.graph.fileAttachment',
#         'contentBytes': media_content.decode('utf-8'),
#         'name': os.path.basename(file_path)
#     }
#     return data_body


APP_ID = '6f70962f-db23-458a-87f5-3342190d8674'
SCOPES = ['Mail.Send', 'Mail.ReadWrite']
CLIENT_SECRET = 'Uv28Q~zM5h1Oq47q8YwYrNx01JwW4Hqo-3faibdC'

access_token = generate_access_token(app_id=APP_ID, scopes=SCOPES)
headers = {
    'Authorization': 'Bearer ' + access_token['access_token']
}
print(headers)

request_body = {
    'message': {
        'toRecipients': [
            {
                'emailAddress': {
                    'address': 'tony.humbert27@outlook.com'
                }
            }
        ],
        'subject': 'You got an email',
        'importance': 'normal',
        'body': {
            'contentType': 'HTML',
            'content': '<b>Be Awesome</b>.  With extended token for real!'
        },
        # 'attachments': [
        #     draft_attachment('hello.txt'),
        #     draft_attachment('image.png')
        # ]
    }
}

GRAPH_ENDPOINT = 'https://graph.microsoft.com/v1.0'
endpoint = GRAPH_ENDPOINT + '/me/sendMail'

response = requests.post(endpoint, headers=headers, json=request_body)
if response.status_code == 202:
    print('Email sent')
else:
    print(response.reason)

