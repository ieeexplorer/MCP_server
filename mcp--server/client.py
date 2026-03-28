# client.py
"""Simple MCP client that starts a local server and calls the 'add' tool."""

import asyncio

from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client


async def main() -> None:
    """Create a client session, initialize it, and call the add tool."""
    # Define how to start the MCP server process.
    server_params = StdioServerParameters(
        command="python",
        args=["server.py"],
    )

    # Start the server over stdio and open a client session.
    async with stdio_client(server_params) as (reader, writer):
        async with ClientSession(reader, writer) as session:
            # Perform the MCP handshake/initialization before using tools.
            await session.initialize()

            # Call the 'add' tool with sample arguments.
            result = await session.call_tool("add", arguments={"a": 3, "b": 4})

            # Keep the output text exactly the same.
            print(f"Result of add tool: {result}")


if __name__ == "__main__":
    asyncio.run(main())
