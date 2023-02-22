from google.cloud import pubsub_v1
import random
import names
import json

project_id = "cloud-consulting-sandbox"
topic_id = "capstonev3-stream-topic"

publisher = pubsub_v1.PublisherClient()
# The `topic_path` method creates a fully qualified identifier
# in the form `projects/{project_id}/topics/{topic_id}`
topic_path = publisher.topic_path(project_id, topic_id)

def random_person(request):
    id =  random.randrange(1000,9999)
    genders = ['male', 'female']
    this_gender = random.choice(genders)
    first_name = names.get_first_name(gender=this_gender)
    last_name = names.get_last_name()
    email = last_name+'.'+first_name+"@randomized.com"
    ip_address = str(random.randrange(100, 300))+'.'+str(random.randrange(100, 300))+'.'+str(random.randrange(50, 99))+'.'+str(random.randrange(10, 30))

    data_str = {"id":id,"first_name":first_name,"last_name":last_name,"email":email,"gender":this_gender,"ip_address":ip_address}

    # Data must be a bytestring
    data = json.dumps(data_str, indent=2).encode("utf-8")
    # When you publish a message, the client returns a future.
    publisher.publish(topic_path, data)

    print(f"Published {id} to {topic_path}.")