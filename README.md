# Persistent ID Plugin

A professional Godot plugin for generating and managing unique persistent IDs for game objects.

## Features

- **Generate unique persistent IDs** that survive editor reloads
- **Registry management** with search and export functionality
- **Runtime support** for dynamic ID generation
- **Clean inspector UI** with copy-to-clipboard functionality
- **Management dock** for viewing all IDs in your project

## Installation

1. Download the plugin from the Godot Asset Library
2. Extract to your project's `addons/` folder
3. Enable "Persistent ID" in Project Settings > Plugins

## Usage

### Basic Usage

1. Add a `PersistentID` resource to any node or script
2. In the inspector, click "Generate ID" 
3. Copy the ID to use in your code or use the id property to access the ID
4. The ID will persist through editor reloads

### Runtime Usage

```gdscript
# Create a new PersistentID at runtime
var my_id = PersistentID.create_new()
print("Generated ID: ", my_id.id)

# Or generate manually
var my_id2 = PersistentID.new()
my_id2.generate_id()
```

### Management

Use the **Persistent ID Manager** dock to:
- View all IDs in your project
- Search for specific IDs
- Export the registry for backup
- Clean up unused IDs

## ID Format

IDs follow the format: `pid_timestamp_random`
- Example: `pid_1748849054.214_397464`
- Guaranteed unique across your project
- Safe for use as keys, references, or identifiers

## Requirements

- Godot 4.0+
- No external dependencies

## License

MIT License - see LICENSE.txt for details

## Support

Report issues or request features on GitHub: [https://github.com/AdamNaghs/Godot-4-Persistent-ID-Plugin]
