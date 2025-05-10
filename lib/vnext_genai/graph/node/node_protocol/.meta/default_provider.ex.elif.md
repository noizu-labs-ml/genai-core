# NodeProtocol.DefaultProvider

## Overview
The `GenAI.Graph.NodeProtocol.DefaultProvider` provides default implementations for the `GenAI.Graph.NodeProtocol`. It uses `function_exported?` to check if a module implements specific functions, and falls back to default implementations when needed.

## Key Functions

### Node Creation and Management
- `new/2`, `do_new/2`: Creates new graph nodes with default values
- `node/2`: Retrieves a nested node by ID
- `nodes/2`: Gets all nodes in a graph node
- `build_node_lookup/2`: Builds a lookup table for nodes in a graph
- `build_handle_lookup/2`: Builds a lookup table for handles in a graph

### Node Properties
- `node_type/1`, `do_node_type/1`: Gets the type of a node
- `id/1`, `do_id/1`: Gets the ID of a node
- `handle/1`, `do_handle/1`: Gets the handle of a node
- `handle_record/1`, `do_handle_record/1`: Gets the handle record of a node
- `handle/2`, `do_handle/2`: Gets the handle with a default value
- `name/1`, `do_name/1`: Gets the name of a node
- `name/2`, `do_name/2`: Gets the name with a default value
- `description/1`, `do_description/1`: Gets the description of a node
- `description/2`, `do_description/2`: Gets the description with a default value
- `with_id/1`, `do_with_id/1`, `do_with_id!/1`: Ensures a node has an ID

### Link Management
- `register_link/4`, `do_register_link/4`: Registers a link between nodes
- `outbound_links/3`, `do_outbound_links/3`: Gets outbound links from a node
- `inbound_links/3`, `do_inbound_links/3`: Gets inbound links to a node

### Node Processing
- `process_node/6`, `do_process_node/6`: Processes a node in a graph
- `apply_node_directives/6`: Applies directives during node processing
- `process_node_response/6`, `do_process_node_response/6`: Handles the response after processing a node

### Inspection Helpers
- `inspect_custom_details/2`: Provides custom details for inspection
- `inspect_low_detail/2`: Provides low-detail inspection
- `inspect_medium_detail/2`: Provides medium-detail inspection
- `inspect_high_detail/2`: Provides high-detail inspection
- `inspect_full_detail/2`: Provides full-detail inspection

## Usage
This provider is used by default for all graph nodes that implement the `GenAI.Graph.NodeProtocol`. It provides common functionality for working with graph nodes, while allowing modules to override specific behaviors.