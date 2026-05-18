using System.Data;
using System.IO;
using FluentAssertions;
using ModernWMS.Core.Extentions;
using ModernWMS.Core.Utility;
using Newtonsoft.Json;
using Xunit;

namespace ModernWMS.Tests.Unit.Core;

public sealed class UtilityConversionTests
{
    [Fact]
    public void ModelConvertHelperMapsPrimitiveAndNullableColumns()
    {
        var table = CreateConversionTable();
        table.Rows.Add("42", "3.5", "12.75", "true", "2026-05-19 10:20:30", " demo ", "7", "Z", "ignored");

        var result = ModelConvertHelper<ConversionRow>.ConvertToModel(table);

        result.Should().ContainSingle();
        var row = result.Single();
        row.IntValue.Should().Be(42);
        row.DoubleValue.Should().Be(3.5d);
        row.DecimalValue.Should().Be(12.75m);
        row.BoolValue.Should().BeTrue();
        row.DateValue.Should().Be(new DateTime(2026, 5, 19, 10, 20, 30));
        row.StringValue.Should().Be(" demo ");
        row.NullableByte.Should().Be(7);
        row.Character.Should().Be('Z');
        row.ReadOnlyMarker.Should().Be("readonly");
    }

    [Fact]
    public void ModelConvertHelperUsesDefaultsForEmptyValues()
    {
        var table = CreateConversionTable();
        table.Rows.Add("", "", "", "", "", "", DBNull.Value, "A", "ignored");

        var result = ModelConvertHelper<ConversionRow>.ConvertToModel(table);

        result.Should().ContainSingle();
        var row = result.Single();
        row.IntValue.Should().Be(0);
        row.DoubleValue.Should().Be(0d);
        row.DecimalValue.Should().Be(0m);
        row.BoolValue.Should().BeFalse();
        row.DateValue.Should().Be(new DateTime(1900, 1, 1));
        row.StringValue.Should().BeEmpty();
        row.NullableByte.Should().BeNull();
        row.Character.Should().Be('A');
    }

    [Fact]
    public void ModelConvertHelperSkipsRowsThatCannotBeConverted()
    {
        var table = CreateConversionTable();
        table.Rows.Add("1", "1.1", "2.2", "true", "2026-05-19", "ok", "1", "A", "ignored");
        table.Rows.Add("NaN", "bad", "bad", "not-bool", "oops", "broken", "x", "AB", "ignored");

        var result = ModelConvertHelper<ConversionRow>.ConvertToModel(table);

        result.Should().HaveCount(1);
        result.Single().IntValue.Should().Be(1);
    }

    [Fact]
    public void UtilConvertParsesNumericInputsAndFallbacks()
    {
        object nullValue = null!;

        nullValue.ObjToInt().Should().Be(0);
        nullValue.ObjToInt(99).Should().Be(99);
        nullValue.ObjToDouble().Should().Be(0d);
        nullValue.ObjToDouble(9.9d).Should().Be(9.9d);
        nullValue.ObjToDecimal().Should().Be(0m);
        nullValue.ObjToDecimal(7.7m).Should().Be(7.7m);
        "".ObjToInt().Should().Be(0);
        "".ObjToInt(12).Should().Be(0);
        "bad".ObjToInt().Should().Be(0);
        "".ObjToDouble().Should().Be(0d);
        "".ObjToDouble(2.5d).Should().Be(0d);
        "bad".ObjToDouble().Should().Be(0d);
        "".ObjToDecimal().Should().Be(0m);
        "".ObjToDecimal(3.5m).Should().Be(0m);
        "bad".ObjToDecimal().Should().Be(0m);
        "12".ObjToInt().Should().Be(12);
        "12".ObjToInt(99).Should().Be(12);
        "bad".ObjToInt(5).Should().Be(5);
        "2.5".ObjToDouble().Should().Be(2.5d);
        "2.5".ObjToDouble(9.9d).Should().Be(2.5d);
        "bad".ObjToDouble(1.5d).Should().Be(1.5d);
        "3.75".ObjToDecimal().Should().Be(3.75m);
        "3.75".ObjToDecimal(7.7m).Should().Be(3.75m);
        "bad".ObjToDecimal(1.25m).Should().Be(1.25m);
    }

    [Fact]
    public void UtilConvertParsesStringsDatesAndBooleanValues()
    {
        object nullValue = null!;

        "  text  ".ObjToString().Should().Be("text");
        nullValue.ObjToString().Should().BeEmpty();
        nullValue.ObjToString("fallback").Should().Be("fallback");
        "2026-05-19".ObjToDate().Should().Be(new DateTime(2026, 5, 19));
        "2026-05-19".ObjToDate(new DateTime(2020, 1, 1)).Should().Be(new DateTime(2026, 5, 19));
        "invalid".ObjToDate(new DateTime(2020, 1, 1)).Should().Be(new DateTime(2020, 1, 1));
        "true".ObjToBool().Should().BeTrue();
        "maybe".ObjToBool().Should().BeFalse();
        UtilConvert.MinDate.Should().Be(new DateTime(1900, 1, 1));
    }

    [Fact]
    public void UtilConvertComparisonHelpersCompareNumbersAndDates()
    {
        var boundary = new DateTime(2026, 5, 19, 12, 0, 0);

        "5".IsLessThan(6).Should().BeTrue();
        "5".IsLessThanOrEqual(5).Should().BeTrue();
        "6".IsGreaterThan(5).Should().BeTrue();
        "6".IsGreaterThanOrEqual(6).Should().BeTrue();
        "2026-05-18".IsLessThan(boundary).Should().BeTrue();
        "2026-05-19 12:00:00".IsLessThanOrEqual(boundary).Should().BeTrue();
        "2026-05-20".IsGreaterThan(boundary).Should().BeTrue();
        "2026-05-19 12:00:00".IsGreaterThanOrEqual(boundary).Should().BeTrue();
    }

    [Fact]
    public void JsonHelperSerializesCamelCasePayloadsAndDataTables()
    {
        var payload = new JsonPayload
        {
            DisplayName = "Demo",
            CreatedAt = new DateTime(2026, 5, 19, 8, 30, 0)
        };
        var table = new DataTable();
        table.Columns.Add("name", typeof(string));
        table.Columns.Add("created_at", typeof(DateTime));
        table.Rows.Add(DBNull.Value, payload.CreatedAt);

        var objectJson = JsonHelper.SerializeObject(payload);
        var tableJson = JsonHelper.SerializeDataTable(table, replaceNullToEmpty: true);
        var roundTrip = JsonHelper.DeserializeObject<JsonPayload>(objectJson);

        objectJson.Should().Contain("\"displayName\": \"Demo\"");
        objectJson.Should().Contain("\"createdAt\": \"2026-05-19 08:30:00\"");
        tableJson.Should().Contain("\"\"");
        tableJson.Should().Contain("2026-05-19 08:30:00");
        roundTrip.Should().NotBeNull();
        roundTrip!.DisplayName.Should().Be("Demo");
        roundTrip.CreatedAt.Should().Be(payload.CreatedAt);
    }

    [Fact]
    public void JsonStringTrimConverterTrimsStringsFormatsDatesAndWritesNulls()
    {
        var converter = new JsonStringTrimConverter();

        converter.CanConvert(typeof(string)).Should().BeTrue();
        converter.CanConvert(typeof(int)).Should().BeFalse();
        ReadWithConverter(converter, "\"  demo  \"").Should().Be("demo");
        ReadWithConverter(converter, "null").Should().BeNull();
        ReadDateWithConverter(converter, "\"2026-05-19T08:30:00\"").Should().Be("2026-05-19 08:30:00");
        WriteWithConverter(converter, "  trimmed  ").Should().Be("\"trimmed\"");
        WriteWithConverter(converter, null).Should().Be("null");
    }

    private static DataTable CreateConversionTable()
    {
        var table = new DataTable();
        table.Columns.Add(nameof(ConversionRow.IntValue), typeof(string));
        table.Columns.Add(nameof(ConversionRow.DoubleValue), typeof(string));
        table.Columns.Add(nameof(ConversionRow.DecimalValue), typeof(string));
        table.Columns.Add(nameof(ConversionRow.BoolValue), typeof(string));
        table.Columns.Add(nameof(ConversionRow.DateValue), typeof(string));
        table.Columns.Add(nameof(ConversionRow.StringValue), typeof(string));
        table.Columns.Add(nameof(ConversionRow.NullableByte), typeof(string));
        table.Columns.Add(nameof(ConversionRow.Character), typeof(string));
        table.Columns.Add(nameof(ConversionRow.ReadOnlyMarker), typeof(string));
        return table;
    }

    private static object? ReadWithConverter(JsonStringTrimConverter converter, string json)
    {
        using var reader = new JsonTextReader(new StringReader(json));
        reader.Read();
        return converter.ReadJson(reader, typeof(string), null, JsonSerializer.CreateDefault());
    }

    private static object? ReadDateWithConverter(JsonStringTrimConverter converter, string json)
    {
        using var reader = new JsonTextReader(new StringReader(json))
        {
            DateParseHandling = DateParseHandling.DateTime
        };
        reader.Read();
        return converter.ReadJson(reader, typeof(string), null, JsonSerializer.CreateDefault());
    }

    private static string WriteWithConverter(JsonStringTrimConverter converter, string? value)
    {
        using var stringWriter = new StringWriter();
        using var writer = new JsonTextWriter(stringWriter);
        converter.WriteJson(writer, value, JsonSerializer.CreateDefault());
        writer.Flush();
        return stringWriter.ToString();
    }

    private sealed class ConversionRow
    {
        public int IntValue { get; set; }

        public double DoubleValue { get; set; }

        public decimal DecimalValue { get; set; }

        public bool BoolValue { get; set; }

        public DateTime DateValue { get; set; }

        public string StringValue { get; set; } = string.Empty;

        public byte? NullableByte { get; set; }

        public char Character { get; set; }

        public string ReadOnlyMarker => "readonly";
    }

    private sealed class JsonPayload
    {
        public string DisplayName { get; set; } = string.Empty;

        public DateTime CreatedAt { get; set; }
    }
}
