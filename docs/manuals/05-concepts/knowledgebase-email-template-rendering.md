> **[EXAMPLE - Magento 2 + React]** This concept doc is from a Magento 2 + React project. It will be deleted when you run `/setup-project`. It serves as an example of the kind of architecture knowledge you should capture for your own project.

# Email template rendering

Magento's email template system (`TransportBuilder`) takes template variables as an associative array and renders them with `{{var data.field_name}}` syntax. Important caveats:

- **Only scalar values render correctly.** If you pass a JSON string or array, the template renders it literally (e.g. `[{"product_label":"Wheelchair",...}]`). You must deserialise structured data in PHP and either format it as HTML or create separate template variables.
- **Escaping is automatic** for `{{var}}` directives, but custom HTML within variables must be pre-escaped in PHP.
- **Template IDs** are declared in `etc/email_templates.xml` and referenced via admin configuration paths for customisability.
