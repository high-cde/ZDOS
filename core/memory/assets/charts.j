async function loadChart(id, url, label) {
  const ctx = document.getElementById(id).getContext("2d");
  const r = await fetch(url + "?t=" + Date.now());
  const data = await r.json();

  new Chart(ctx, {
    type: "line",
    data: {
      labels: data.timestamps,
      datasets: [{
        label: label,
        data: data.values,
        borderColor: "#00eaff",
        tension: 0.3
      }]
    },
    options: { responsive: true }
  });
}
