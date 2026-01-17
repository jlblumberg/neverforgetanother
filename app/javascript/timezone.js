// Shared timezone detection and update functionality
window.detectAndUpdateTimezone = function(updateUrl, options = {}) {
  const { onSuccess, onError, showAlerts = false } = options;
  
  try {
    const detectedTimezone = Intl.DateTimeFormat().resolvedOptions().timeZone;
    if (detectedTimezone) {
      fetch(updateUrl, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({ timezone: detectedTimezone })
      }).then(response => {
        if (response.ok) {
          if (onSuccess) {
            onSuccess();
          } else {
            // Default: reload page to show updated timezone
            window.location.reload();
          }
        } else {
          const errorMsg = 'Failed to update timezone';
          if (showAlerts) {
            alert(errorMsg);
          }
          if (onError) {
            onError(errorMsg);
          } else {
            console.error(errorMsg);
          }
        }
      }).catch(error => {
        const errorMsg = 'Failed to update timezone';
        if (showAlerts) {
          alert(errorMsg);
        }
        if (onError) {
          onError(errorMsg);
        } else {
          console.error(errorMsg, error);
        }
      });
    }
  } catch (e) {
    const errorMsg = 'Failed to detect timezone';
    if (showAlerts) {
      alert(errorMsg);
    }
    if (onError) {
      onError(errorMsg);
    } else {
      console.error(errorMsg, e);
    }
  }
};

