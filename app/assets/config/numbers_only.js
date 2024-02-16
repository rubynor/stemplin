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

  event.target.value = formatToNorwegianKrone(event.target.value);
}

function formatToNorwegianKrone(value) {
  return value.replace(/[^\d,]/g, "");
}

function updateInput(event) {
  const input = event.target;
  const value = input.value;
  const formattedValue = formatToNorwegianKrone(value);
  input.value = formattedValue;

  const originalValue = value.replace(/\D/g, "");
  document.getElementById("input2").value = originalValue * 100;
}
