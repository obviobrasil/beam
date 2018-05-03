<#-- Licensed to the Apache Software Foundation (ASF) under one or more contributor
  license agreements. See the NOTICE file distributed with this work for additional
  information regarding copyright ownership. The ASF licenses this file to
  You under the Apache License, Version 2.0 (the "License"); you may not use
  this file except in compliance with the License. You may obtain a copy of
  the License at http://www.apache.org/licenses/LICENSE-2.0 Unless required
  by applicable law or agreed to in writing, software distributed under the
  License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS
  OF ANY KIND, either express or implied. See the License for the specific
  language governing permissions and limitations under the License. -->

boolean IfNotExistsOpt() :
{
}
{
    <IF> <NOT> <EXISTS> { return true; }
|
    { return false; }
}

boolean IfExistsOpt() :
{
}
{
    <IF> <EXISTS> { return true; }
|
    { return false; }
}

SqlNodeList Options() :
{
    final Span s;
    final List<SqlNode> list = Lists.newArrayList();
}
{
    <OPTIONS> { s = span(); } <LPAREN>
    [
        Option(list)
        (
            <COMMA>
            Option(list)
        )*
    ]
    <RPAREN> {
        return new SqlNodeList(list, s.end(this));
    }
}

void Option(List<SqlNode> list) :
{
    final SqlIdentifier id;
    final SqlNode value;
}
{
    id = SimpleIdentifier()
    value = Literal() {
        list.add(id);
        list.add(value);
    }
}

List<Schema.Field> FieldList() :
{
    final Span s;
    final List<Schema.Field> fields = Lists.newArrayList();
}
{
    <LPAREN>  { fields.add(Field()); }
    (
        <COMMA> { fields.add(Field()); }
    )*
    <RPAREN> {
        return fields;
    }
}

Schema.Field Field() :
{
    final String name;
    final Schema.FieldType type;
    final boolean nullable;
    SqlNode comment = null;
    Schema.Field field = null;
}
{
    name = Identifier()
    (
        type = FieldType()
        {
            field = Schema.Field.of(name, type);
        }
        (
            <NULL> { field = field.withNullable(true); }
        |
            <NOT> <NULL> { field = field.withNullable(false); }
        |
            { field = field.withNullable(true); }
        )
        [
            <COMMENT> comment = StringLiteral()
            {
                if (comment != null) {
                    String commentString =
                        ((NlsString) SqlLiteral.value(comment)).getValue();
                    field = field.withDescription(commentString);
                }
            }
        ]
        {
            return field;
        }
    )
}

/**
 * Note: This example is probably out of sync with the code.
 *
 * CREATE TABLE ( IF NOT EXISTS )?
 *   ( database_name '.' )? table_name '(' column_def ( ',' column_def )* ')'
 *   TYPE type_name
 *   ( COMMENT comment_string )?
 *   ( LOCATION location_string )?
 *   ( TBLPROPERTIES tbl_properties )?
 */
SqlCreate SqlCreateTable(Span s, boolean replace) :
{
    final boolean ifNotExists;
    final SqlIdentifier id;
    List<Schema.Field> fieldList = null;
    SqlNode type = null;
    SqlNode comment = null;
    SqlNode location = null;
    SqlNode tblProperties = null;
}
{
    <TABLE> ifNotExists = IfNotExistsOpt()
    id = CompoundIdentifier()
    fieldList = FieldList()
    <TYPE> type = StringLiteral()
    [ <COMMENT> comment = StringLiteral() ]
    [ <LOCATION> location = StringLiteral() ]
    [ <TBLPROPERTIES> tblProperties = StringLiteral() ]
    {
        return
            new SqlCreateTable(
                s.end(this),
                replace,
                ifNotExists,
                id,
                fieldList,
                type,
                comment,
                location,
                tblProperties);
    }
}

SqlDrop SqlDropTable(Span s, boolean replace) :
{
    final boolean ifExists;
    final SqlIdentifier id;
}
{
    <TABLE> ifExists = IfExistsOpt() id = CompoundIdentifier() {
        return SqlDdlNodes.dropTable(s.end(this), ifExists, id);
    }
}

Schema.FieldType FieldType() :
{
    final SqlTypeName simpleTypeName;
    final SqlTypeName collectionTypeName;
    Schema.FieldType fieldType;
    final Span s = Span.of();
}
{
    simpleTypeName = SqlTypeName(s)
    {
        s.end(this);
        fieldType = CalciteUtils.toFieldType(simpleTypeName);
    }
    [
        collectionTypeName = CollectionTypeName()
        {
            if (collectionTypeName != null) {

                Schema.FieldType collectionType = CalciteUtils.toFieldType(collectionTypeName);
                fieldType = collectionType.withCollectionElementType(fieldType);
            }
        }
    ]
    {
        return fieldType;
    }
}

SqlTypeName CollectionTypeName() :
{
}
{
    <ARRAY> {
        return SqlTypeName.ARRAY;
    }
}



// End parserImpls.ftl
