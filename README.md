# Contentful Image Tagger

Tag your Contenful images using AWS rekognition

## Install

create a env.yml with your contentful credentials
```YAML

default_env: &default_env
  contentful_space_id: <your_contentful_space_id>
  contentful_access_token: <your_contentful_access_token>
dev:
   <<: *default_env
```

then deploy it...

```
serverless deploy --stage=dev
```

## Usage

```
GET '/tags?entry_id=<contenful_entry_id>&reference_path=<reference_path>&tag_path=<tag_path>
```

|field|description|required|
| --- | --------- | ------ |
|entry_id| the contentful entry id | yes |
|reference_path| the reference path to the image on the entry object for example if the asset is stored under the content model eg. 'profile_picture' or 'image'| yes|
|tag_path| the tag path under the content model, needs to be a text list type eg. tags, labels, meta_data etc| no|

## Example
![GitHub Logo](https://images.pexels.com/photos/39317/chihuahua-dog-puppy-cute-39317.jpeg?auto=compress&cs=tinysrgb&dpr=3&h=750&w=1260)

### response

```JSON
{
  "entry_id": "34h43dfd1",
  "tags": [
    "puppy",
    "mug",
    "grass"
  ],
  "error": null
}
```

And your tags should be set on the field you put as your tag path

