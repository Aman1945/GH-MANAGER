const nodemailer = require('nodemailer');

/**
 * Email service — uses Gmail SMTP if EMAIL_USER/EMAIL_PASS are set.
 * Fails gracefully: if credentials are missing or sending fails, it logs
 * and returns false instead of throwing, so booking flows never break.
 */

let transporter = null;

function getTransporter() {
  if (transporter) return transporter;
  if (!process.env.EMAIL_USER || !process.env.EMAIL_PASS) return null;

  transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
      user: process.env.EMAIL_USER,
      pass: process.env.EMAIL_PASS
    }
  });
  return transporter;
}

/**
 * Send a booking confirmation email to the guest.
 * @returns {Promise<boolean>} true if sent, false if skipped/failed
 */
async function sendApprovalEmail({ to, guestName, guestHouseName, roomNumber, checkIn, checkOut }) {
  const tx = getTransporter();
  if (!tx) {
    console.log(`[emailService] Skipped — no EMAIL_USER/EMAIL_PASS configured. Would have emailed ${to}.`);
    return false;
  }

  const fmt = (d) => new Date(d).toDateString();

  try {
    await tx.sendMail({
      from: `"GH Manager" <${process.env.EMAIL_USER}>`,
      to,
      subject: 'Your Booking is Confirmed — GH Manager',
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 560px; margin: 0 auto; border: 1px solid #E5E7EB; border-radius: 12px; overflow: hidden;">
          <div style="background: #0F4C3A; color: #fff; padding: 20px 24px;">
            <h2 style="margin: 0;">Booking Confirmed</h2>
          </div>
          <div style="padding: 24px; color: #111827;">
            <p>Dear ${guestName},</p>
            <p>We're delighted to confirm your booking at <strong>${guestHouseName}</strong>.</p>
            <table style="width: 100%; border-collapse: collapse; margin: 16px 0;">
              <tr><td style="padding: 8px 0; color: #6B7280;">Room</td><td style="padding: 8px 0; font-weight: 600;">${roomNumber}</td></tr>
              <tr><td style="padding: 8px 0; color: #6B7280;">Check-in</td><td style="padding: 8px 0; font-weight: 600;">${fmt(checkIn)}</td></tr>
              <tr><td style="padding: 8px 0; color: #6B7280;">Check-out</td><td style="padding: 8px 0; font-weight: 600;">${fmt(checkOut)}</td></tr>
            </table>
            <p>We look forward to hosting you.</p>
            <p style="color: #6B7280; font-size: 13px;">— GH Manager Team</p>
          </div>
        </div>
      `
    });
    console.log(`[emailService] Approval email sent to ${to}`);
    return true;
  } catch (err) {
    console.error(`[emailService] Failed to send to ${to}:`, err.message);
    return false;
  }
}

module.exports = { sendApprovalEmail };
