import nodemailer from "nodemailer";
import type { User, EmailOptions, AppInfo } from "./types.js";

// Create reusable transporter object using Stalwart SMTP
const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST || "stalwart",
  port: parseInt(process.env.SMTP_PORT || "25"),
  secure: false, // true for 465, false for other ports
  auth: process.env.SMTP_USER
    ? {
        user: process.env.SMTP_USER,
        pass: process.env.SMTP_PASSWORD,
      }
    : undefined,
  tls: {
    rejectUnauthorized: false,
  },
});

// Email templates
const templates = {
  welcome: (user: User): EmailOptions => ({
    subject: "Welcome to Zoo Identity",
    html: `
      <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
        <h1 style="color: #1a1a1a; font-size: 24px; margin-bottom: 20px;">Welcome to Zoo Identity!</h1>
        <p style="color: #6b7280; line-height: 1.6;">Hi ${user.name},</p>
        <p style="color: #6b7280; line-height: 1.6;">
          Your Zoo Identity account has been created successfully. You now have access to all Zoo applications with a single sign-on.
        </p>
        <div style="background: #f9fafb; border: 1px solid #e5e7eb; border-radius: 8px; padding: 20px; margin: 20px 0;">
          <p style="margin: 0 0 10px 0; color: #374151;"><strong>Account Details:</strong></p>
          <p style="margin: 5px 0; color: #6b7280;">Username: <strong>${user.username}</strong></p>
          <p style="margin: 5px 0; color: #6b7280;">Email: <strong>${user.email}</strong></p>
        </div>
        <p style="color: #6b7280; line-height: 1.6;">
          You can manage your account and connected applications at any time by visiting your 
          <a href="http://auth.zoo/dashboard" style="color: #3b82f6; text-decoration: none;">account dashboard</a>.
        </p>
        <hr style="border: none; border-top: 1px solid #e5e7eb; margin: 30px 0;">
        <p style="color: #9ca3af; font-size: 14px;">
          This email was sent from Zoo Identity. If you didn't create an account, please ignore this email.
        </p>
      </div>
    `,
  }),

  appAuthorized: (user: User, app: AppInfo): EmailOptions => ({
    subject: `New app connected: ${app.clientName}`,
    html: `
      <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
        <h1 style="color: #1a1a1a; font-size: 24px; margin-bottom: 20px;">New Application Connected</h1>
        <p style="color: #6b7280; line-height: 1.6;">Hi ${user.name},</p>
        <p style="color: #6b7280; line-height: 1.6;">
          A new application has been authorized to access your Zoo Identity account.
        </p>
        <div style="background: #f9fafb; border: 1px solid #e5e7eb; border-radius: 8px; padding: 20px; margin: 20px 0;">
          <p style="margin: 0 0 10px 0; color: #374151;"><strong>Application Details:</strong></p>
          <p style="margin: 5px 0; color: #6b7280;">Name: <strong>${app.clientName}</strong></p>
          <p style="margin: 5px 0; color: #6b7280;">Permissions: <strong>${app.scopes.join(", ")}</strong></p>
          <p style="margin: 5px 0; color: #6b7280;">Authorized: <strong>${new Date().toLocaleString()}</strong></p>
        </div>
        <p style="color: #6b7280; line-height: 1.6;">
          If you didn't authorize this application, you can revoke its access from your 
          <a href="http://auth.zoo/dashboard" style="color: #3b82f6; text-decoration: none;">account dashboard</a>.
        </p>
        <div style="margin-top: 20px;">
          <a href="http://auth.zoo/dashboard" style="display: inline-block; background: #3b82f6; color: white; padding: 10px 20px; text-decoration: none; border-radius: 6px;">
            Manage Connected Apps
          </a>
        </div>
        <hr style="border: none; border-top: 1px solid #e5e7eb; margin: 30px 0;">
        <p style="color: #9ca3af; font-size: 14px;">
          This security alert was sent from Zoo Identity to help keep your account secure.
        </p>
      </div>
    `,
  }),

  appRevoked: (user: User, app: AppInfo): EmailOptions => ({
    subject: `App access revoked: ${app.clientName}`,
    html: `
      <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
        <h1 style="color: #1a1a1a; font-size: 24px; margin-bottom: 20px;">Application Access Revoked</h1>
        <p style="color: #6b7280; line-height: 1.6;">Hi ${user.name},</p>
        <p style="color: #6b7280; line-height: 1.6;">
          You have successfully revoked access for the following application:
        </p>
        <div style="background: #fee2e2; border: 1px solid #fecaca; border-radius: 8px; padding: 20px; margin: 20px 0;">
          <p style="margin: 0 0 10px 0; color: #dc2626;"><strong>Revoked Application:</strong></p>
          <p style="margin: 5px 0; color: #7f1d1d;">Name: <strong>${app.clientName}</strong></p>
          <p style="margin: 5px 0; color: #7f1d1d;">Revoked: <strong>${new Date().toLocaleString()}</strong></p>
        </div>
        <p style="color: #6b7280; line-height: 1.6;">
          This application no longer has access to your Zoo Identity account. If you want to use this application again, 
          you'll need to re-authorize it.
        </p>
        <hr style="border: none; border-top: 1px solid #e5e7eb; margin: 30px 0;">
        <p style="color: #9ca3af; font-size: 14px;">
          This confirmation was sent from Zoo Identity.
        </p>
      </div>
    `,
  }),

  passwordChanged: (user: User): EmailOptions => ({
    subject: "Password changed successfully",
    html: `
      <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
        <h1 style="color: #1a1a1a; font-size: 24px; margin-bottom: 20px;">Password Changed</h1>
        <p style="color: #6b7280; line-height: 1.6;">Hi ${user.name},</p>
        <p style="color: #6b7280; line-height: 1.6;">
          Your Zoo Identity password has been changed successfully.
        </p>
        <div style="background: #fef3c7; border: 1px solid #fde68a; border-radius: 8px; padding: 20px; margin: 20px 0;">
          <p style="margin: 0; color: #92400e;">
            <strong>Security Notice:</strong> If you didn't make this change, please contact support immediately 
            and change your password from a secure device.
          </p>
        </div>
        <p style="color: #6b7280; line-height: 1.6;">
          Time of change: <strong>${new Date().toLocaleString()}</strong>
        </p>
        <hr style="border: none; border-top: 1px solid #e5e7eb; margin: 30px 0;">
        <p style="color: #9ca3af; font-size: 14px;">
          This security alert was sent from Zoo Identity to help keep your account secure.
        </p>
      </div>
    `,
  }),
};

export const emailService = {
  async sendWelcomeEmail(user: User): Promise<void> {
    try {
      const { subject, html } = templates.welcome(user);
      await transporter.sendMail({
        from: '"Zoo Identity" <noreply@auth.zoo>',
        to: user.email,
        subject,
        html,
      });
      console.log(`Welcome email sent to ${user.email}`);
    } catch (error) {
      console.error("Error sending welcome email:", error);
    }
  },

  async sendAppAuthorizedEmail(user: User, app: AppInfo): Promise<void> {
    try {
      const { subject, html } = templates.appAuthorized(user, app);
      await transporter.sendMail({
        from: '"Zoo Identity" <noreply@auth.zoo>',
        to: user.email,
        subject,
        html,
      });
      console.log(`App authorized email sent to ${user.email}`);
    } catch (error) {
      console.error("Error sending app authorized email:", error);
    }
  },

  async sendAppRevokedEmail(user: User, app: AppInfo): Promise<void> {
    try {
      const { subject, html } = templates.appRevoked(user, app);
      await transporter.sendMail({
        from: '"Zoo Identity" <noreply@auth.zoo>',
        to: user.email,
        subject,
        html,
      });
      console.log(`App revoked email sent to ${user.email}`);
    } catch (error) {
      console.error("Error sending app revoked email:", error);
    }
  },

  async sendPasswordChangedEmail(user: User): Promise<void> {
    try {
      const { subject, html } = templates.passwordChanged(user);
      await transporter.sendMail({
        from: '"Zoo Identity" <noreply@auth.zoo>',
        to: user.email,
        subject,
        html,
      });
      console.log(`Password changed email sent to ${user.email}`);
    } catch (error) {
      console.error("Error sending password changed email:", error);
    }
  },
};
