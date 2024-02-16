function restrictInput(event) {
  const allowedChars = /[0-9,]/;
  const inputChar = event.data;

  if (!allowedChars.test(inputChar)) {
    event.target.value = event.target.value.replace(/[^\d,]/g, "");
  }

  const newValue = event.target.value;
  const commaCount = (newValue.match(/,/g) || []).length;

  if (commaCount > 1 && inputChar === ",") {
    event.target.value = newValue.slice(0, -1);
  }

  event.target.value = formatInput(event.target.value);
}

function formatInput(value) {
  return value.replace(/[^\d,]/g, "");
}

function updateInput(event) {
  const input = event.target;
  const value = input.value;
  const formattedValue = formatInput(value);
  input.value = formattedValue;

  const numericValue = parseFloat(formattedValue.replace(",", "."));
  const formattedNumericValue = isNaN(numericValue)
    ? ""
    : (numericValue * 100).toLocaleString("nb-NO", {
        minimumFractionDigits: 2,
        maximumFractionDigits: 2,
      });
  document.getElementById("input2").value = formattedNumericValue;
}
