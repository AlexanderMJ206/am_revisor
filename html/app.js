let selectedPlayer = null;
let cfg = {};
let progressTimer = null;
let cachedPlayers = [];

const app = document.getElementById('app');
const playersEl = document.getElementById('players');
const clientDropdownBtn = document.getElementById('clientDropdownBtn');
const clientDropdown = document.getElementById('clientDropdown');
const clientSearch = document.getElementById('clientSearch');
const dropdownLabel = document.getElementById('dropdownLabel');
const dropdownMeta = document.getElementById('dropdownMeta');

const selectedClient = document.getElementById('selectedClient');
const amountInput = document.getElementById('amount');
const percentInput = document.getElementById('percent');
const clientGets = document.getElementById('clientGets');
const revisorGets = document.getElementById('revisorGets');

const summaryAmount = document.getElementById('summaryAmount');
const summaryFee = document.getElementById('summaryFee');
const summaryPayout = document.getElementById('summaryPayout');
const summaryCut = document.getElementById('summaryCut');
const riskLevel = document.getElementById('riskLevel');
const topRisk = document.getElementById('topRisk');
const orderId = document.getElementById('orderId');
const queueText = document.getElementById('queueText');

const progressWrap = document.getElementById('progressWrap');
const progressBar = document.getElementById('progressBar');
const progressPercent = document.getElementById('progressPercent');
const progressText = document.getElementById('progressText');
const chartTooltip = document.getElementById('chartTooltip');

function post(name, data = {}) {
    return fetch(`https://${GetParentResourceName()}/${name}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data)
    }).then(res => res.json());
}

function money(n) {
    n = Number(n) || 0;
    return new Intl.NumberFormat('da-DK').format(Math.floor(n)) + ' DKK';
}

function calculate() {
    const amount = Number(amountInput.value) || 0;
    let percent = Number(percentInput.value) || 0;

    if (cfg.maxPercent && percent > cfg.maxPercent) {
        percent = cfg.maxPercent;
        percentInput.value = percent;
    }

    const cut = Math.floor(amount * (percent / 100));
    const payout = Math.max(amount - cut, 0);

    clientGets.value = money(payout);
    revisorGets.value = money(cut);

    summaryAmount.textContent = money(amount);
    summaryFee.textContent = percent + '%';
    summaryPayout.textContent = money(payout);
    summaryCut.textContent = money(cut);

    let risk = 'LAV';
    if (percent > 25) risk = 'HØJ';
    else if (percent > 10) risk = 'MIDDEL';

    riskLevel.textContent = risk;
    topRisk.textContent = risk;
}

function renderPlayers(players) {
    cachedPlayers = players || cachedPlayers || [];
    const query = (clientSearch?.value || '').toLowerCase().trim();
    const filtered = cachedPlayers.filter(player => (player.name || '').toLowerCase().includes(query));

    playersEl.innerHTML = '';

    if (!filtered || filtered.length === 0) {
        playersEl.innerHTML = `
            <div class="no-players">
                <strong>Ingen klienter fundet</strong>
                <span>Kom tættere på klienten eller refresh.</span>
            </div>
        `;
        return;
    }

    filtered.forEach(player => {
        const item = document.createElement('div');
        item.className = 'player';
        if (selectedPlayer && selectedPlayer.id === player.id) item.classList.add('selected');

        item.innerHTML = `
            <div>
                <span class="player-name">${player.name}</span>
                <span class="player-sub">Spiller tæt på</span>
            </div>
            <span class="player-distance">${player.distance}m</span>
        `;

        item.addEventListener('click', () => {
            selectedPlayer = player;
            selectedClient.value = player.name;

            dropdownLabel.textContent = player.name;
            dropdownMeta.textContent = `${player.distance} meter væk`;

            clientDropdown.classList.add('hidden');
            clientDropdownBtn.classList.remove('open');

            renderPlayers(cachedPlayers);
        });

        playersEl.appendChild(item);
    });
}

function openTerminal(data) {
    cfg = data.config || {};
    selectedPlayer = null;
    selectedClient.value = '';
    dropdownLabel.textContent = 'Ingen klient valgt';
    dropdownMeta.textContent = 'Klik for at vælge klient tæt på';
    riskLevel.textContent = 'LAV';
    topRisk.textContent = 'LAV';
    queueText.textContent = 'KLAR';
    clientSearch.value = '';
    clientDropdown.classList.add('hidden');
    clientDropdownBtn.classList.remove('open');

    amountInput.value = '';
    percentInput.value = cfg.defaultPercent || 10;
    orderId.textContent = 'ORD-' + Math.floor(1000 + Math.random() * 8999);

    app.classList.remove('hidden');
    renderPlayers(data.players || []);
    calculate();
    drawChart();
}

function closeTerminal() {
    app.classList.add('hidden');
    clearInterval(progressTimer);
    progressTimer = null;
    progressWrap.classList.add('hidden');
    chartTooltip.classList.add('hidden');
    clientDropdown.classList.add('hidden');
    clientDropdownBtn.classList.remove('open');
}

function startProgress(duration) {
    clearInterval(progressTimer);
    progressWrap.classList.remove('hidden');
    progressBar.style.width = '0%';
    progressPercent.textContent = '0%';
    progressText.textContent = 'Behandler transaktion...';
    queueText.textContent = 'AKTIV';

    const start = Date.now();

    progressTimer = setInterval(() => {
        const elapsed = Date.now() - start;
        const pct = Math.min(100, Math.floor((elapsed / duration) * 100));

        progressBar.style.width = pct + '%';
        progressPercent.textContent = pct + '%';

        if (pct >= 100) {
            clearInterval(progressTimer);
            progressTimer = null;
            progressText.textContent = 'Afventer bekræftelse...';
            queueText.textContent = 'KLAR';
        }
    }, 120);
}

function showTooltip(evt, data) {
    const chart = document.querySelector('.chart');
    const rect = chart.getBoundingClientRect();

    let x = evt.clientX - rect.left;
    let y = evt.clientY - rect.top;

    chartTooltip.textContent = `${data.label}: ${data.value}`;
    chartTooltip.className = `chart-tooltip ${data.color}`;

    // Smart placement:
    // If candle is high/top, tooltip opens below instead of being cut off.
    // If candle is too far right, move it left inside chart.
    const tooltipWidth = 170;
    x = clamp(x, tooltipWidth / 2, rect.width - tooltipWidth / 2);

    if (y < 55) {
        chartTooltip.classList.add('tooltip-below');
        y = y + 8;
    } else {
        chartTooltip.classList.remove('tooltip-below');
        y = clamp(y, 60, rect.height - 8);
    }

    chartTooltip.style.left = `${x}px`;
    chartTooltip.style.top = `${y}px`;
}

function hideTooltip() {
    chartTooltip.classList.add('hidden');
}

function clamp(n, min, max) {
    return Math.max(min, Math.min(max, n));
}

function drawChart() {
    const candles = document.getElementById('candles');
    const linePath = document.getElementById('linePath');
    const areaPath = document.getElementById('areaPath');

    candles.innerHTML = '';
    const points = [];
    let price = 125;

    for (let i = 0; i < 38; i++) {
        price += (Math.random() - 0.38) * 18;
        price = clamp(price, 48, 178);

        const x = 20 + i * 17.3;
        const y = clamp(230 - price, 56, 226);
        points.push([x, y]);

        const open = clamp(y + (Math.random() - 0.5) * 24, 18, 250);
        const close = clamp(y + (Math.random() - 0.5) * 24, 18, 250);
        const high = clamp(Math.min(open, close) - Math.random() * 11, 46, 250);
        const low = clamp(Math.max(open, close) + Math.random() * 16, 18, 258);
        const up = close < open;
        const marketValue = Math.floor(10000 + price * 280 + Math.random() * 9000);
        const percent = (up ? '+' : '-') + (Math.random() * 5 + 0.25).toFixed(2) + '%';

        const wick = document.createElementNS('http://www.w3.org/2000/svg', 'line');
        wick.setAttribute('x1', x);
        wick.setAttribute('x2', x);
        wick.setAttribute('y1', high);
        wick.setAttribute('y2', low);
        wick.setAttribute('class', up ? 'wick-up' : 'wick-down');
        wick.setAttribute('stroke-width', '2');

        const rect = document.createElementNS('http://www.w3.org/2000/svg', 'rect');
        rect.setAttribute('x', x - 4);
        rect.setAttribute('y', Math.min(open, close));
        rect.setAttribute('width', 8);
        rect.setAttribute('height', Math.max(Math.abs(close - open), 5));
        rect.setAttribute('class', up ? 'candle-up' : 'candle-down');

        const glow = document.createElementNS('http://www.w3.org/2000/svg', 'circle');
        glow.setAttribute('cx', x);
        glow.setAttribute('cy', close);
        glow.setAttribute('r', 8);
        glow.setAttribute('class', 'hover-glow');
        glow.setAttribute('fill', up ? '#42ff8c' : '#ff1f35');
        glow.setAttribute('opacity', '0');

        const zone = document.createElementNS('http://www.w3.org/2000/svg', 'rect');
        zone.setAttribute('x', x - 9);
        zone.setAttribute('y', 0);
        zone.setAttribute('width', 18);
        zone.setAttribute('height', 270);
        zone.setAttribute('class', 'hover-zone');

        zone.addEventListener('mousemove', (evt) => {
            showTooltip(evt, {
                label: up ? 'Grøn kurs' : 'Rød kurs',
                value: `${money(marketValue)} / ${percent}`,
                color: up ? 'green' : 'red'
            });
        });

        zone.addEventListener('mouseenter', () => {
            glow.setAttribute('opacity', '0.42');
            glow.setAttribute('r', '10');
        });

        zone.addEventListener('mouseleave', () => {
            glow.setAttribute('opacity', '0');
            glow.setAttribute('r', '8');
            hideTooltip();
        });

        candles.appendChild(wick);
        candles.appendChild(rect);
        candles.appendChild(glow);
        candles.appendChild(zone);
    }

    linePath.setAttribute('points', points.map(p => p.join(',')).join(' '));

    const area = `M ${points[0][0]} 270 L ` + points.map(p => p.join(' ')).join(' L ') + ` L ${points[points.length - 1][0]} 270 Z`;
    areaPath.setAttribute('d', area);
}

document.getElementById('closeBtn').addEventListener('click', () => {
    post('close');
});

clientDropdownBtn.addEventListener('click', () => {
    clientDropdown.classList.toggle('hidden');
    clientDropdownBtn.classList.toggle('open');

    if (!clientDropdown.classList.contains('hidden')) {
        setTimeout(() => clientSearch.focus(), 25);
    }
});

clientSearch.addEventListener('input', () => {
    renderPlayers(cachedPlayers);
});

document.addEventListener('click', (e) => {
    const inside = e.target.closest('.client-field');
    if (!inside && clientDropdown && !clientDropdown.classList.contains('hidden')) {
        clientDropdown.classList.add('hidden');
        clientDropdownBtn.classList.remove('open');
    }
});

document.getElementById('startBtn').addEventListener('click', async () => {
    if (!selectedPlayer) return;

    const amount = Number(amountInput.value);
    const percent = Number(percentInput.value);

    const res = await post('startWash', {
        targetId: selectedPlayer.id,
        amount,
        percent
    });

    if (res.ok) {
        startProgress(res.duration);
    }
});

amountInput.addEventListener('input', calculate);
percentInput.addEventListener('input', calculate);

document.addEventListener('keydown', e => {
    if (e.key === 'Escape') {
        post('close');
    }
});

window.addEventListener('message', e => {
    const { action, data } = e.data;

    if (action === 'open') openTerminal(data);
    if (action === 'close') closeTerminal();

    if (action === 'washingStarted') {
        startProgress(data.duration || 12000);
    }

    if (action === 'washingFinished') {
        progressBar.style.width = '100%';
        progressPercent.textContent = '100%';
        progressText.textContent = 'Transaktion færdig';
        queueText.textContent = 'KLAR';
        setTimeout(() => progressWrap.classList.add('hidden'), 2500);
    }
});
