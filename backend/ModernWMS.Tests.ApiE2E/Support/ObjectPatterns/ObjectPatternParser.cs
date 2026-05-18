using System.Globalization;

namespace ModernWMS.Tests.ApiE2E.Support.ObjectPatterns;

public static class ObjectPatternParser
{
    public static ObjectPatternNode Parse(string text)
    {
        var parser = new Parser(text);
        return parser.ParseRoot();
    }

    private sealed class Parser
    {
        private readonly string _text;
        private int _position;

        public Parser(string text)
        {
            _text = text;
        }

        public ObjectPatternNode ParseRoot()
        {
            SkipSeparators();
            var op = ReadOperator();
            var value = ParseValue();
            SkipSeparators();
            if (!IsEnd)
            {
                throw Error($"Unexpected trailing input '{Current}'.");
            }

            return new ObjectPatternNode(op, value);
        }

        private object? ParseValue()
        {
            SkipSeparators();
            if (IsEnd)
            {
                throw Error("Expected value.");
            }

            return Current switch
            {
                '{' => ParseObject(),
                '[' => ParseArray(),
                '\'' or '"' => ParseQuotedString(),
                '*' => ReadWildcard(),
                _ => ParseBareValue()
            };
        }

        private IReadOnlyDictionary<string, object?> ParseObject()
        {
            Consume('{');
            var result = new Dictionary<string, object?>();
            while (true)
            {
                SkipSeparators();
                if (TryConsume('}'))
                {
                    return result;
                }

                var key = ParseKey();
                SkipWhitespace();
                Consume(':');
                result[key] = ParseValue();
            }
        }

        private IReadOnlyList<object?> ParseArray()
        {
            Consume('[');
            var result = new List<object?>();
            while (true)
            {
                SkipSeparators();
                if (TryConsume(']'))
                {
                    return result;
                }

                result.Add(ParseValue());
            }
        }

        private string ParseKey()
        {
            SkipWhitespace();
            if (Current is '\'' or '"')
            {
                return ParseQuotedString();
            }

            var start = _position;
            while (!IsEnd && !char.IsWhiteSpace(Current) && Current != ':')
            {
                _position++;
            }

            if (_position == start)
            {
                throw Error("Expected object key.");
            }

            return _text[start.._position];
        }

        private object? ParseBareValue()
        {
            var token = ReadBareToken();
            if (token.Equals("true", StringComparison.OrdinalIgnoreCase)) return true;
            if (token.Equals("false", StringComparison.OrdinalIgnoreCase)) return false;
            if (token.Equals("null", StringComparison.OrdinalIgnoreCase)) return null;
            if (long.TryParse(token, NumberStyles.Integer, CultureInfo.InvariantCulture, out var integer)) return integer;
            if (decimal.TryParse(token, NumberStyles.Number, CultureInfo.InvariantCulture, out var number)) return number;
            return token;
        }

        private string ReadBareToken()
        {
            var start = _position;
            while (!IsEnd && !char.IsWhiteSpace(Current) && Current != ',' && Current != ']' && Current != '}')
            {
                _position++;
            }

            if (_position == start)
            {
                throw Error("Expected token.");
            }

            return _text[start.._position];
        }

        private string ParseQuotedString()
        {
            var quote = Current;
            _position++;
            var start = _position;
            while (!IsEnd && Current != quote)
            {
                _position++;
            }

            if (IsEnd)
            {
                throw Error("Unterminated string literal.");
            }

            var value = _text[start.._position];
            _position++;
            return value;
        }

        private ObjectPatternWildcard ReadWildcard()
        {
            Consume('*');
            return ObjectPatternWildcard.Instance;
        }

        private ObjectPatternOperator ReadOperator()
        {
            if (TryConsume('=')) return ObjectPatternOperator.Equals;
            if (TryConsume(':')) return ObjectPatternOperator.Contains;
            throw Error("Pattern must start with '=' or ':'.");
        }

        private void SkipSeparators()
        {
            while (!IsEnd && (char.IsWhiteSpace(Current) || Current == ','))
            {
                _position++;
            }
        }

        private void SkipWhitespace()
        {
            while (!IsEnd && char.IsWhiteSpace(Current))
            {
                _position++;
            }
        }

        private bool TryConsume(char expected)
        {
            if (!IsEnd && Current == expected)
            {
                _position++;
                return true;
            }

            return false;
        }

        private void Consume(char expected)
        {
            if (!TryConsume(expected))
            {
                throw Error($"Expected '{expected}'.");
            }
        }

        private bool IsEnd => _position >= _text.Length;

        private char Current => _text[_position];

        private FormatException Error(string message) => new($"{message} Position {_position} in pattern: {_text}");
    }
}
