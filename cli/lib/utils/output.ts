import yoctoSpinner from "yocto-spinner";

export function startSpinner(text: string): ReturnType<typeof yoctoSpinner> {
  return yoctoSpinner({ text }).start();
}
