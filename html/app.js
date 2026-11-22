const card = document.getElementById('card');
const positions = ['top-right', 'top-left', 'bottom-right', 'bottom-left', 'center-right', 'center-left'];

function setText(id, text) {
    document.getElementById(id).textContent = text == null ? '' : String(text);
}

function show(data, position) {
    card.className = 'card';
    card.classList.add(positions.includes(position) ? position : 'top-right');
    if (data.status) card.classList.add(data.status);

    setText('title', data.title);
    const alcohol = document.getElementById('alcohol');
    const drugs = document.getElementById('drugs');
    drugs.replaceChildren();

    if (data.kind === 'alcohol') {
        alcohol.style.display = '';
        drugs.style.display = 'none';
        setText('value', data.value);
        setText('unit', data.unit);
    } else {
        alcohol.style.display = 'none';
        drugs.style.display = '';
        (data.rows || []).forEach((row) => {
            const line = document.createElement('div');
            line.className = 'drug-row';
            const label = document.createElement('span');
            label.textContent = row.label;
            const result = document.createElement('span');
            result.className = row.positive ? 'pos' : 'neg';
            result.textContent = row.text;
            line.append(label, result);
            drugs.appendChild(line);
        });
    }

    const status = document.getElementById('status');
    status.className = 'status ' + (data.status || 'neutral');
    status.textContent = data.statusText || '';

    const labels = data.labels || {};
    setText('labelSubject', labels.subject);
    setText('labelOfficer', labels.officer);
    setText('labelDate', labels.date);
    setText('closeHint', labels.close);
    setText('subject', data.subject);
    setText('officer', data.officer);
    setText('date', data.date);
    document.getElementById('brand').style.display = data.branding ? '' : 'none';
}

function hide() {
    card.classList.add('hidden');
}

window.addEventListener('message', (event) => {
    const msg = event.data || {};
    if (msg.action === 'show' && msg.data) show(msg.data, msg.position);
    else if (msg.action === 'hide') hide();
});
