// ==================== STATUS BAR ====================
function setStatus(message, type = 'info') {
    const bar = document.getElementById('status-bar');
    const text = document.getElementById('status');
    text.textContent = message;
    bar.className = 'status-bar';
    if (type === 'error') bar.classList.add('error');
    if (type === 'success') bar.classList.add('success');
}

// ==================== MESSAGE HANDLING ====================
function addMessage(content, type = 'ai') {
    const container = document.getElementById('chat-messages');
    const messageDiv = document.createElement('div');
    messageDiv.className = `message ${type}-message`;
    const contentDiv = document.createElement('div');
    contentDiv.className = 'message-content';
    if (typeof content === 'string') {
        contentDiv.innerHTML = content;
    } else {
        contentDiv.appendChild(content);
    }
    messageDiv.appendChild(contentDiv);
    container.appendChild(messageDiv);
}

// ==================== TRANSLATION ====================
async function sendMessage() {
    const input = document.getElementById('message-input');
    const text = input.value.trim();
    if (!text) return;

    addMessage(`<strong>You:</strong> ${text}`, 'user');
    input.value = '';
    setStatus('🔄 Translating...');

    try {
        const response = await fetch('/invoke', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ text })
        });
        if (!response.ok) throw new Error(`API error: ${response.status}`);
        const data = await response.json();
        const translation = data.translation || 'No translation available';
        addMessage(`<strong>Translation:</strong> ${translation}`);
        setStatus('✅ Done', 'success');
    } catch (error) {
        console.error('Translation error:', error);
        addMessage(`❌ Translation failed: ${error.message}`);
        setStatus('Translation failed', 'error');
    }
}

// ==================== INIT ====================
window.addEventListener('load', () => {
    document.getElementById('message-input').focus();
    setStatus('Ready — type something in English');
});
