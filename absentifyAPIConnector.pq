// This file contains your Data Connector logic
section absentifyAPIConnector;

api_key = Extension.CurrentCredential()[Key];

[DataSource.Kind="absentifyAPIConnector", Publish="absentifyAPIConnector.Publish"]

shared absentifyAPIConnector.NavTableNested = () as table =>
    let

        NavTable = (tb as table) => Table.ToNavigationTable(tb, {"Key"}, "Name", "Data", "ItemKind", "ItemName", "IsLeaf"),
        table_header = {"Name", "Key", "Data", "ItemKind", "ItemName", "IsLeaf"},
        lv1 = #table(
            table_header,
            {
                {"Get all members", "Get all members", absentifyAPIConnector.GetAllMembers(), "table", "table", "true"},
                {"Get all departments", "Get all departments", absentifyAPIConnector.GetAllDepartments(), "table", "table", "true"},
                {"Get all leave types", "Get all leave types", absentifyAPIConnector.GetAllLeaveTypes(), "table", "table", "true"},
                //{"Get current workspace settings", "Get current workspace settings", absentifyAPIConnector.GetCurrentWorkspaceSettings(), "table", "table", "true"},
                //{"Get all public holidays", "Get all public holidays", absentifyAPIConnector.GetAllPublicHolidays(), "table", "table", "true"}
                {"Get all requests", "Get all requests", absentifyAPIConnector.GetAllRequests, "function", "function", "true"}
            }   
        )
    in
        NavTable(lv1);


absentifyAPIConnector.GetAllRequests = (start as date, end as date) =>
    let
        endpoint = "requests",
        dt1 = Date.ToText(start, "yyyy-MM-dd") & "T00:00:00.000Z",
        dt2 = Date.ToText(end, "yyyy-MM-dd") & "T00:00:00.000Z",
        params = [start = dt1, end = dt2],
        json = absentifyAPIConnector.GetData(endpoint, params),
        tb = toTable(json, 1)
    in
        tb;



absentifyAPIConnector.GetAllPublicHolidays = () => 
    let
        endpoint = "public_holidays",
        json = absentifyAPIConnector.GetData(endpoint, []),
        tb = toTable(json, 1)
    in
        tb;

absentifyAPIConnector.GetCurrentWorkspaceSettings = () => 
    let
        endpoint = "workspace",
        json = absentifyAPIConnector.GetData(endpoint, []),
        tb = toTable(json, 1)
    in
        tb;


absentifyAPIConnector.GetAllLeaveTypes = () => 
    let
        endpoint = "leave_types",
        json = absentifyAPIConnector.GetData(endpoint, []),
        tb = toTable(json, 1)
    in
        tb;


absentifyAPIConnector.GetAllDepartments = () => 
    let
        endpoint = "departments",
        json = absentifyAPIConnector.GetData(endpoint, []),
        tb = toTable(json, 1)
    in
        tb;


absentifyAPIConnector.GetAllMembers = () => 
    let
        endpoint = "members",
        json = absentifyAPIConnector.GetData(endpoint, []),
        tb = toTable(json, 1)
    in
        tb;


absentifyAPIConnector.GetData = (endpoint as text, params as record) =>
    let
        url = "https://api.absentify.com/api/v1/" & endpoint,
        headers = [
            #"x-api-key" = api_key, 
            #"Content-Type" = "application/json"
            ],

        options = [
            Headers = headers, 
            Query = params
            ],

        json = Json.Document(Web.Contents(url, options))
    in
        json;

// Data Source Kind description
absentifyAPIConnector = [
    TestConnection = (dataSourcePath) => {"absentifyAPIConnector.NavTableNested"},
    Authentication = [
        Key = [
            KeyLabel = "Enter here the key you have generated in absentify (Only available in Enterprise Plan)"
            ]
        // UsernamePassword = [],
        // Windows = [],
        //Implicit = []
    ],
    Label = Extension.LoadString("DataSourceLabel")
];

// Data Source UI publishing description
absentifyAPIConnector.Publish = [
    Beta = true,
    Category = "Other",
    ButtonText = { Extension.LoadString("ButtonTitle"), Extension.LoadString("ButtonHelp") },
    LearnMoreUrl = "https://powerbi.microsoft.com/",
    SourceImage = absentifyAPIConnector.Icons,
    SourceTypeImage = absentifyAPIConnector.Icons
];

absentifyAPIConnector.Icons = [
    Icon16 = { Extension.Contents("absentifyAPIConnector16.png"), Extension.Contents("absentifyAPIConnector20.png"), Extension.Contents("absentifyAPIConnector24.png"), Extension.Contents("absentifyAPIConnector32.png") },
    Icon32 = { Extension.Contents("absentifyAPIConnector32.png"), Extension.Contents("absentifyAPIConnector40.png"), Extension.Contents("absentifyAPIConnector48.png"), Extension.Contents("absentifyAPIConnector64.png") }
];


toTable = (lstrec as list, optional index as number) as table =>
    let
        fieldnames = 
            let
                toprows = if index is null then lstrec else List.FirstN(lstrec, index),
                listfields = List.Transform(toprows, Record.FieldNames),
                namesdistinct = List.Union(listfields)
            in
                namesdistinct,
        tbl = Table.FromRecords(lstrec, fieldnames, MissingField.UseNull)
    in
        try tbl otherwise null;

Table.ToNavigationTable = (
    table as table,
    keyColumns as list,
    nameColumn as text,
    dataColumn as text,
    itemKindColumn as text,
    itemNameColumn as text,
    isLeafColumn as text
) as table =>
    let
        tableType = Value.Type(table),
        newTableType = Type.AddTableKey(tableType, keyColumns, true) meta 
        [
            NavigationTable.NameColumn = nameColumn, 
            NavigationTable.DataColumn = dataColumn,
            NavigationTable.ItemKindColumn = itemKindColumn, 
            Preview.DelayColumn = itemNameColumn, 
            NavigationTable.IsLeafColumn = isLeafColumn
        ],
        navigationTable = Value.ReplaceType(table, newTableType)
    in
        navigationTable;