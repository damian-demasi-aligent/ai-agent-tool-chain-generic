---
name: data-patch
description: Create a Magento 2 data patch or schema change for "$ARGUMENTS".
argument-hint: Description of the DB change (e.g., "add is_featured boolean product attribute", "add phone column to store_location table")
disable-model-invocation: true
metadata:
  capabilities: [magento]
---

Create a Magento 2 data patch or schema change for "$ARGUMENTS".

Before starting, **read CLAUDE.md** for the project's vendor namespace, module inventory, PHP conventions, Magento CLI commands, PHP quality commands, and the Reuse Before Reimplementing table (especially data patch and DB schema entries).

## Step 1: Determine the patch type

Parse $ARGUMENTS to identify what kind of database change is needed:

| Need | Mechanism | Key files |
|---|---|---|
| Add/modify columns on an existing table | Declarative schema (`db_schema.xml`) | `etc/db_schema.xml` + `etc/db_schema_whitelist.json` |
| Create a new custom table | Declarative schema (`db_schema.xml`) | `etc/db_schema.xml` + `etc/db_schema_whitelist.json` |
| Add a product EAV attribute | Data patch (`Setup/Patch/Data/`) | `Setup/Patch/Data/<Name>.php` using `EavSetupFactory` |
| Add a customer EAV attribute | Data patch (`Setup/Patch/Data/`) | `Setup/Patch/Data/<Name>.php` using `CustomerSetupFactory` |
| Modify an existing EAV attribute | Data patch (`Setup/Patch/Data/`) | `Setup/Patch/Data/<Name>.php` using `EavSetup::updateAttribute()` |
| Insert/update rows in a table | Data patch (`Setup/Patch/Data/`) | `Setup/Patch/Data/<Name>.php` using direct DB adapter |
| Add a column AND populate it with data | Both: `db_schema.xml` for the column + data patch to populate |

If the description is ambiguous, ask the user to clarify before proceeding.

## Step 2: Study existing examples in this project

Read the relevant reference files from CLAUDE.md's Reuse Before Reimplementing table to match project conventions:

### For declarative schema (`db_schema.xml`)

Search for existing `db_schema.xml` files in the project's custom modules. Look for patterns matching your use case:
- Adding columns to core Magento tables
- Adding columns to inventory/store tables
- Whitelist JSON format

### For data patches (EAV attributes)

Read existing patches from the paths listed in CLAUDE.md's reuse table. Look for patterns matching:
- Product boolean attribute
- Product attribute with dependencies
- Modify existing attribute properties
- Customer text attribute (with form assignment)

Key conventions to observe in existing patches:
- Attribute codes stored as `public const` on the patch class (or referenced from a model constant)
- Product attributes grouped under the project's attribute group constant — read existing patches to find it
- `startSetup()` / `endSetup()` wraps all DB operations
- `getAliases()` returns `[]` and `getDependencies()` returns `[]` (unless there is an explicit ordering need)
- Data patches implement `DataPatchInterface`; add `PatchRevertableInterface` only when a `revert()` method is provided
- Class name describes the action: `Add<Thing>`, `Update<Thing>`, `Remove<Thing>`
- Follow the PHP conventions from CLAUDE.md (copyright header, strict_types, promoted properties)

## Step 3: Determine the target module

Choose the module based on the domain:
- Product attributes → the catalog module (unless the attribute is domain-specific to another module)
- Customer attributes → the customer module
- Quote/order table columns → the module that owns the feature using those columns
- New custom tables → the module that owns the domain

Verify the module exists under the vendor namespace path from CLAUDE.md and has a `registration.php`.

## Step 4: Show the plan

Before writing any files, present the plan:

**For declarative schema:**
```
Module: <Vendor>_<Module>
Table: <table_name>

Columns to add/modify:
  1. <column_name> — <xsi:type> — nullable: <yes/no> — default: <value>
  2. ...

Files to create/modify:
  - etc/db_schema.xml (modify|create)
  - etc/db_schema_whitelist.json (modify|create)
```

**For data patches:**
```
Module: <Vendor>_<Module>
Patch: Setup/Patch/Data/<ClassName>.php
Entity: <Product|Customer|etc.>

Attribute(s):
  1. <attribute_code> — type: <type> — input: <input> — label: "<label>"
  2. ...

Dependencies: [none | list of patch classes that must run first]
Revertable: yes/no
```

Wait for the user to confirm before proceeding.

## Step 5: Create the files

### Declarative schema — `db_schema.xml`

If the file already exists, add columns inside the existing `<table>` element (or add a new `<table>` if targeting a different table). Do not overwrite existing columns.

Column type reference:
```xml
<!-- String -->
<column xsi:type="varchar" name="field_name" nullable="true" length="255" comment="Description"/>

<!-- Text (unlimited length) -->
<column xsi:type="text" name="field_name" nullable="true" comment="Description"/>

<!-- Integer -->
<column xsi:type="int" name="field_name" unsigned="false" nullable="true" identity="false" comment="Description"/>

<!-- Small integer -->
<column xsi:type="smallint" name="field_name" unsigned="true" nullable="true" identity="false" default="0" comment="Description"/>

<!-- Boolean (stored as smallint) -->
<column xsi:type="boolean" name="field_name" nullable="false" default="1"/>

<!-- Decimal -->
<column xsi:type="decimal" name="field_name" precision="12" scale="4" nullable="true" comment="Description"/>

<!-- Auto-increment primary key -->
<column xsi:type="int" name="entity_id" unsigned="true" nullable="false" identity="true" comment="Entity ID"/>
```

For new tables, include constraints:
```xml
<table name="custom_table" resource="default" engine="innodb" comment="Description">
    <column xsi:type="int" name="entity_id" unsigned="true" nullable="false" identity="true" comment="Entity ID"/>
    <!-- other columns -->
    <constraint xsi:type="primary" referenceId="PRIMARY">
        <column name="entity_id"/>
    </constraint>
</table>
```

### Declarative schema — `db_schema_whitelist.json`

This file must list every column, constraint, and index that the module's `db_schema.xml` declares. It authorises the declarative schema system to manage those items.

If the file already exists, merge the new entries into the existing JSON structure. Format:
```json
{
    "table_name": {
        "column": {
            "column_name": true
        },
        "constraint": {
            "PRIMARY": true
        },
        "index": {
            "INDEX_NAME": true
        }
    }
}
```

**Important:** The whitelist can also be generated automatically using the Magento CLI (check CLAUDE.md Commands for the CLI wrapper):
```bash
<cli-wrapper> setup:db-declaration:generate-whitelist --module-name=<Vendor>_<Module>
```
Mention this to the user as an alternative.

### Data patch — EAV product attribute

Read an existing product attribute patch in the project, then follow the same structure:

```php
<?php
// [project copyright header — see CLAUDE.md PHP Conventions]
declare(strict_types=1);

namespace <Vendor>\<Module>\Setup\Patch\Data;

use Magento\Catalog\Model\Product;
use Magento\Eav\Setup\EavSetupFactory;
use Magento\Framework\Setup\ModuleDataSetupInterface;
use Magento\Framework\Setup\Patch\DataPatchInterface;

class <ClassName> implements DataPatchInterface
{
    public const ATTRIBUTE_CODE = '<attribute_code>';

    public function __construct(
        private readonly ModuleDataSetupInterface $moduleDataSetup,
        private readonly EavSetupFactory $eavSetupFactory
    ) {
    }

    public function apply()
    {
        $this->moduleDataSetup->getConnection()->startSetup();
        $eavSetup = $this->eavSetupFactory->create(['setup' => $this->moduleDataSetup]);

        $eavSetup->addAttribute(
            Product::ENTITY,
            self::ATTRIBUTE_CODE,
            [
                'label' => '<Human Readable Label>',
                'type' => '<backend_type>',       // varchar, int, text, decimal, datetime
                'input' => '<frontend_input>',     // text, boolean, select, multiselect, textarea, date
                'required' => false,
                'user_defined' => true,
                'system' => false,
                'sort_order' => <N>,
                'global' => ScopedAttributeInterface::SCOPE_STORE,
                'used_in_product_listing' => true,
                'group' => '<attribute_group_constant>',  // read existing patches for the project's constant
                'is_used_in_grid' => true,
                'is_visible_in_grid' => false,
                'is_filterable_in_grid' => true,
            ]
        );

        $this->moduleDataSetup->getConnection()->endSetup();
        return $this;
    }

    public function getAliases()
    {
        return [];
    }

    public static function getDependencies()
    {
        return [];
    }
}
```

### Data patch — EAV customer attribute

Read an existing customer attribute patch in the project. Key differences from product attributes:
- Uses `CustomerSetupFactory` instead of `EavSetupFactory`
- Must assign to form codes via `customer_form_attribute` table insert
- Uses `SetFactory` and `AttributeRepositoryInterface` for attribute set/group assignment
- Consider implementing `PatchRevertableInterface` with a `revert()` method

### Data patch — Modify existing attribute

Read an existing attribute modification patch in the project — use `$eavSetup->updateAttribute()` to change specific attribute properties.

### Data patch — Direct DB operations

For non-EAV data (inserting rows, updating config values, etc.):
```php
public function apply()
{
    $this->moduleDataSetup->getConnection()->startSetup();

    $connection = $this->moduleDataSetup->getConnection();
    $tableName = $this->moduleDataSetup->getTable('table_name');

    $connection->insertMultiple($tableName, [
        ['column_a' => 'value1', 'column_b' => 'value2'],
    ]);

    $this->moduleDataSetup->getConnection()->endSetup();
    return $this;
}
```

## Step 6: Post-creation steps

After creating the files, inform the user of the deployment commands needed (check CLAUDE.md Commands for the exact CLI wrapper):

**For declarative schema changes:**
```
setup:upgrade
setup:di:compile
cache:flush
```

**For data patches:**
```
setup:upgrade    # This runs all pending data patches
cache:flush
```

**To verify a data patch ran:**
```
setup:db:status  # Shows pending patches
```

## Step 7: Verify

Run the project's PHP quality commands from CLAUDE.md Commands section on the new files. Report any issues found. If the commands are not available in this environment, list what manual checks should be run before committing.
