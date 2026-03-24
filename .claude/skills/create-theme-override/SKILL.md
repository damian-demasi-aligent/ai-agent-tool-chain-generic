---
name: create-theme-override
description: Create a theme-level override for "$ARGUMENTS" (format: Module_Name/path/to/template or Module_Name for layout XML).
argument-hint: Module_Name/path/to/template.phtml or Module_Name (for layout XML)
disable-model-invocation: true
metadata:
  capabilities: [magento-theme]
---

Create a theme-level override for "$ARGUMENTS" (format: Module_Name/path/to/template or Module_Name for layout XML).

Before starting, **read CLAUDE.md** for the project's theme path.

1. First, locate the original file in `vendor/` to understand what we're overriding. If $ARGUMENTS is a template, find the `.phtml` file. If it's a layout handle, find the `.xml` file.

2. Copy the original file to the correct location under the project's theme directory (from CLAUDE.md) preserving the Magento override directory structure.

3. Show me the original content and ask what changes I want before modifying the override. Do NOT modify the override without confirmation.

Remember: for layout XML, prefer using `referenceBlock`/`referenceContainer` to make targeted changes rather than copying the entire layout file.
