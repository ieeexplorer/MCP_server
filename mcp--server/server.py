# server.py
"""Simple MCP server that exposes a tool, a resource, and a prompt."""

from mcp.server.fastmcp import FastMCP

# Create the MCP server instance with a custom display name.
mcp = FastMCP("Demo Server")


@mcp.tool()
def add(a: int, b: int) -> int:
    """
    Add two numbers together.

    Args:
        a: First number.
        b: Second number.

    Returns:
        The sum of a and b.
    """
    return a + b


@mcp.resource("greeting://{name}")
def get_greeting(name: str) -> str:
    """
    Return a personalized greeting for the given name.

    Args:
        name: The name to greet.

    Returns:
        A greeting message for the supplied name.
    """
    return f"Hello, {name}!"


@mcp.prompt()
def review_code(code: str) -> str:
    """
    Build a prompt for reviewing code.

    Args:
        code: The code to review.

    Returns:
        A prompt asking the LLM to review the provided code.
    """
    return f"Please review this code:\n\n{code}"


if __name__ == "__main__":
    mcp.run()
