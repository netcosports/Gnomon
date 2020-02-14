# Swaggen templates

This is set of templates for generating gnomon client

## Usage

* install Swaggen https://github.com/yonaskolb/SwagGen#installing
* copy templates folder
* generate client with command:

```sh
swaggen generate --clean all -o modelType:struct -o modelInheritance:false -o modelSuffix:Model -o mutableModels:true --template <templates-folder-path> <yml-spec-file-path>
```
