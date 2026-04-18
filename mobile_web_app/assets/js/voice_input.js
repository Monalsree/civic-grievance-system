// ===================================
// Voice Input Module
// Web Speech API Integration
// ===================================

class VoiceInput {
    constructor() {
        this.recognition = null;
        this.isListening = false;
        this.targetElement = null;
        this.voiceBtn = null;
        this.statusElement = null;

        this.init();
    }

    init() {
        // Check browser support
        if (!('webkitSpeechRecognition' in window) && !('SpeechRecognition' in window)) {
            console.warn('Speech Recognition not supported in this browser');
            return;
        }

        // Initialize Speech Recognition
        const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
        this.recognition = new SpeechRecognition();

        // Configure recognition
        this.recognition.continuous = false;
        this.recognition.interimResults = true;
        this.recognition.lang = 'en-US'; // Default language
        this.recognition.maxAlternatives = 1;

        // Set up event listeners
        this.setupEventListeners();
    }

    setupEventListeners() {
        if (!this.recognition) return;

        // On speech recognition start
        this.recognition.onstart = () => {
            this.isListening = true;
            this.updateUI('listening');
            this.showStatus('🎤 Listening... Speak now', 'info');
        };

        // On speech recognition result
        this.recognition.onresult = (event) => {
            let interimTranscript = '';
            let finalTranscript = '';

            for (let i = event.resultIndex; i < event.results.length; i++) {
                const transcript = event.results[i][0].transcript;
                if (event.results[i].isFinal) {
                    finalTranscript += transcript + ' ';
                } else {
                    interimTranscript += transcript;
                }
            }

            // Update target element with transcript
            if (this.targetElement) {
                if (finalTranscript) {
                    // Append final transcript to existing text
                    const currentText = this.targetElement.value;
                    this.targetElement.value = currentText + (currentText ? ' ' : '') + finalTranscript.trim();
                    this.showStatus('✅ Voice input captured', 'success');
                }
            }
        };

        // On speech recognition end
        this.recognition.onend = () => {
            this.isListening = false;
            this.updateUI('idle');
        };

        // On speech recognition error
        this.recognition.onerror = (event) => {
            this.isListening = false;
            this.updateUI('idle');

            let errorMessage = 'Voice input error';

            switch (event.error) {
                case 'no-speech':
                    errorMessage = '❌ No speech detected. Please try again.';
                    break;
                case 'audio-capture':
                    errorMessage = '❌ Microphone not found or not accessible.';
                    break;
                case 'not-allowed':
                    errorMessage = '❌ Microphone permission denied.';
                    break;
                case 'network':
                    errorMessage = '❌ Network error. Please check your connection.';
                    break;
                default:
                    errorMessage = `❌ Error: ${event.error}`;
            }

            this.showStatus(errorMessage, 'error');
        };
    }

    // Start listening
    start(targetElement, voiceBtn, statusElement) {
        if (!this.recognition) {
            this.showStatus('❌ Voice input not supported in this browser', 'error');
            return;
        }

        this.targetElement = targetElement;
        this.voiceBtn = voiceBtn;
        this.statusElement = statusElement;

        if (this.isListening) {
            this.stop();
        } else {
            try {
                this.recognition.start();
            } catch (error) {
                console.error('Error starting voice recognition:', error);
                this.showStatus('❌ Failed to start voice input', 'error');
            }
        }
    }

    // Stop listening
    stop() {
        if (this.recognition && this.isListening) {
            this.recognition.stop();
        }
    }

    // Update UI based on state
    updateUI(state) {
        if (!this.voiceBtn) return;

        if (state === 'listening') {
            this.voiceBtn.classList.add('active');
            this.voiceBtn.title = 'Stop listening';
        } else {
            this.voiceBtn.classList.remove('active');
            this.voiceBtn.title = 'Voice input';
        }
    }

    // Show status message
    showStatus(message, type = 'info') {
        if (this.statusElement) {
            this.statusElement.textContent = message;
            this.statusElement.style.color =
                type === 'error' ? '#f5576c' :
                    type === 'success' ? '#43e97b' :
                        '#4facfe';

            // Clear status after 3 seconds
            setTimeout(() => {
                if (this.statusElement) {
                    this.statusElement.textContent = '';
                }
            }, 3000);
        }
    }

    // Change language
    setLanguage(lang) {
        if (this.recognition) {
            this.recognition.lang = lang;
        }
    }
}

// Initialize voice input when DOM is ready
let voiceInput;

if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
        voiceInput = new VoiceInput();
        initVoiceButton();
    });
} else {
    voiceInput = new VoiceInput();
    initVoiceButton();
}

// Initialize voice buttons for all fields
function initVoiceButton() {
    // Get all voice buttons
    const voiceBtns = document.querySelectorAll('.voice-btn');

    if (voiceBtns.length > 0 && voiceInput) {
        voiceBtns.forEach(btn => {
            btn.addEventListener('click', (e) => {
                e.preventDefault();

                // Get the target field ID from data-target attribute
                const targetId = btn.getAttribute('data-target');
                const targetElement = document.getElementById(targetId);
                const statusElement = document.getElementById(`${targetId}Status`);

                if (targetElement) {
                    voiceInput.start(targetElement, btn, statusElement);
                }
            });
        });
    }
}

// Export for use in other scripts
if (typeof module !== 'undefined' && module.exports) {
    module.exports = VoiceInput;
}
