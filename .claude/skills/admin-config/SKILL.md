---
name: admin-config
description: Scaffold Magento 2 admin configuration (system.xml + supporting classes) for "$ARGUMENTS".
argument-hint: Description of config fields needed (e.g., "BCC email address for trial module")
disable-model-invocation: true
metadata:
  capabilities: [magento]
---

Scaffold Magento 2 admin configuration (system.xml + supporting classes) for "$ARGUMENTS".

Before starting, **read CLAUDE.md** for the project's vendor namespace, admin config section convention, PHP conventions, PHP quality commands, and the Reuse Before Reimplementing table.

## Step 1: Parse the request

1. Extract from $ARGUMENTS:
   - **What** is being configured (e.g. "email BCC address for trial module", "shipping rate labels", "enquiry form dropdown options")
   - **Which module** owns this config (check CLAUDE.md module inventory)
   - **Field type(s)** needed — infer from the description:
     - Simple text → `type="text"`
     - Email address → `type="text"` with `<validate>validate-emails</validate>`
     - Number → `type="text"` with `<validate>validate-number</validate>`
     - Yes/No → `type="select"` with `<source_model>Magento\Config\Model\Config\Source\Yesno</source_model>`
     - Dropdown from fixed options → `type="select"` with a custom `source_model`
     - Dropdown from Magento data → `type="select"` with a custom `source_model` that queries collections
     - Multi-line text → `type="textarea"`
     - Dynamic rows (key-value, multi-column table) → `frontend_model` extending `AbstractFieldArray` + `backend_model` of `Magento\Config\Model\Config\Backend\Serialized\ArraySerialized`
2. If the description is ambiguous, ask the user to clarify field types and which module this belongs in before proceeding.

## Step 2: Study existing config in this project

Read the existing `system.xml` and related files in the target module to understand:
- Whether a `system.xml` already exists (if so, add to it — do not overwrite)
- What `sortOrder` values are in use (pick the next logical value)
- Whether a `config.xml` with defaults exists

Also read existing admin config files from CLAUDE.md's Reuse Before Reimplementing table to match project conventions. Look for examples of:
- Simple text/email fields
- Dynamic rows (AbstractFieldArray)
- Custom source models
- ACL resources
- Config defaults

Follow the admin config section convention from CLAUDE.md Conventions — most config uses a shared section with module-specific groups.

## Step 3: Determine what files to create/modify

Based on the field type(s) needed, determine the full set of files:

### Always needed

| File | Action |
|---|---|
| `etc/adminhtml/system.xml` | Create or append — add field(s) to the module's group |

### Conditionally needed

| File | When needed |
|---|---|
| `etc/config.xml` | When fields need default values — create or append |
| `etc/acl.xml` | When creating a **new section** (not when adding fields to the existing shared section) |
| `Block/Adminhtml/Form/Field/<Name>.php` | When using dynamic rows (AbstractFieldArray `frontend_model`) |
| `Model/Config/Source/<Name>.php` | When using a custom dropdown `source_model` |
| `Block/Adminhtml/Form/Field/Select/<Name>.php` | When a dynamic row column needs a dropdown renderer (extends `\Magento\Framework\View\Element\Html\Select`) |

## Step 4: Show the plan

Before writing any files, present the plan to the user:

```
Module: <Vendor>_<Module>
Section: <shared_section> (from CLAUDE.md)
Group: <group_id> (sortOrder: <N>)

Fields:
  1. <field_id> — <type> — "<label>"
     [source_model: ...] [frontend_model: ...] [backend_model: ...] [validation: ...]
  2. ...

Files to create/modify:
  - etc/adminhtml/system.xml (modify|create)
  - etc/config.xml (modify|create) — defaults: <values>
  - Block/Adminhtml/Form/Field/<Name>.php (create)
  - Model/Config/Source/<Name>.php (create)
```

Wait for the user to confirm before proceeding.

## Step 5: Create the files

### system.xml

If the file exists, add the new `<field>` entries inside the existing `<group>`. If the group doesn't exist, add a new `<group>` inside the existing shared `<section>`. Only create a new `<section>` if the module genuinely needs its own top-level admin section (this is rare — check CLAUDE.md Conventions for the shared section convention).

Field template:
```xml
<field id="field_id" translate="label" type="text" sortOrder="10"
       showInDefault="1" showInWebsite="1" showInStore="1" canRestore="1">
    <label>Human Readable Label</label>
</field>
```

Add these child elements as needed:
- `<validate>validate-emails</validate>` for email fields
- `<validate>validate-number</validate>` for numeric fields
- `<comment>Helper text for admin users.</comment>` for guidance
- `<source_model>...</source_model>` for select dropdowns
- `<frontend_model>...</frontend_model>` for dynamic row tables
- `<backend_model>Magento\Config\Model\Config\Backend\Serialized\ArraySerialized</backend_model>` for dynamic row tables

### config.xml

Template for defaults (use the shared section path from CLAUDE.md):
```xml
<?xml version="1.0"?>
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:module:Magento_Store:etc/config.xsd">
    <default>
        <shared_section>
            <group_id>
                <field_id>default_value</field_id>
            </group_id>
        </shared_section>
    </default>
</config>
```

### AbstractFieldArray block (dynamic rows)

Read an existing dynamic rows block in the project for the exact pattern, then follow it:
```php
<?php
// [project copyright header — see CLAUDE.md PHP Conventions]
declare(strict_types=1);

namespace <Vendor>\<Module>\Block\Adminhtml\Form\Field;

use Magento\Config\Block\System\Config\Form\Field\FieldArray\AbstractFieldArray;

class <Name> extends AbstractFieldArray
{
    public const XML_COLUMN_ONE = 'column_one';
    public const XML_COLUMN_TWO = 'column_two';

    protected function _prepareToRender()
    {
        $this->addColumn(self::XML_COLUMN_ONE, ['label' => __('Column One'), 'class' => 'required-entry']);
        $this->addColumn(self::XML_COLUMN_TWO, ['label' => __('Column Two'), 'class' => 'required-entry']);

        $this->_addAfter = false;
        $this->_addButtonLabel = __('Add Another');
    }
}
```

### Source model (custom dropdown)

Read an existing source model in the project for the exact pattern, then follow it:
```php
<?php
// [project copyright header — see CLAUDE.md PHP Conventions]
declare(strict_types=1);

namespace <Vendor>\<Module>\Model\Config\Source;

use Magento\Framework\Data\OptionSourceInterface;

class <Name> implements OptionSourceInterface
{
    public function toOptionArray(): array
    {
        return [
            ['value' => '', 'label' => __('-- Please Select --')],
            // Add options here
        ];
    }
}
```

### ACL resource (only for new sections)

Read an existing `acl.xml` in the project for the exact pattern, nesting under `Magento_Config::config`.

## Step 6: Reading config values in PHP

After creating the config, show the user how to read the value in their module code:

```php
use Magento\Framework\App\Config\ScopeConfigInterface;
use Magento\Store\Model\ScopeInterface;

// Inject ScopeConfigInterface in constructor
public function __construct(
    private readonly ScopeConfigInterface $scopeConfig
) {}

// Read value — use the shared section path from CLAUDE.md
$value = $this->scopeConfig->getValue(
    '<shared_section>/<group_id>/<field_id>',
    ScopeInterface::SCOPE_STORE
);
```

For dynamic rows (serialised arrays):
```php
use Magento\Framework\Serialize\Serializer\Json;

public function __construct(
    private readonly ScopeConfigInterface $scopeConfig,
    private readonly Json $serializer
) {}

$raw = $this->scopeConfig->getValue('<shared_section>/<group_id>/<field_id>', ScopeInterface::SCOPE_STORE);
$rows = $raw ? $this->serializer->unserialize($raw) : [];
```

## Step 7: Verify

Run the project's PHP quality commands from CLAUDE.md Commands section on the new/modified files. Report any issues found. If the commands are not available in this environment, list what manual checks should be run before committing.
