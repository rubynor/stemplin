function restrictInput(event) {
  const allowedChars = /[0-9]/;
  const inputChar = event.data;

  if (!allowedChars.test(inputChar)) {
    event.target.value = event.target.value.replace(/[^0-9]/g, "");
  }
  event.target.value = formatToNorwegianKrone(event.target.value);
}
function formatToNorwegianKrone(value) {
  value = value.replace(/\D/g, "");
  if (value.trim() === "") return "";
  const formattedValue = parseInt(value).toLocaleString("nb-NO");
  return formattedValue;
}

function updateInput(event) {
  const input = event.target;
  const value = input.value;
  const formattedValue = formatToNorwegianKrone(value);
  input.value = formattedValue;

  const originalValue = value.replace(/\D/g, "");
  document.getElementById("input2").value = originalValue / 100;
}
