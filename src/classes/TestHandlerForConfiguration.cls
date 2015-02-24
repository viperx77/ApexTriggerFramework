/*
	The MIT License (MIT)

	Copyright (c) 2015 Douglas Mark Lindell

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.
*/
public with sharing class TestHandlerForConfiguration implements TriggerFramework.IHandler {
	
	public static List<TriggerFramework.Context> contexts = new List<TriggerFramework.Context>();
	public static Boolean reentrantTest = false;
	public static TriggerFramework.Event throwExceptionOn = null;
	
	public void execute(TriggerFramework.Context context) {
		
		system.debug('TestHandlerForConfiguration' + context);		
		contexts.add(context);
		
		if (throwExceptionOn == context.event)
			throw new TriggerFramework.TriggerException('fail on ' + context.event);

		if (reentrantTest) {
			Account firstAccount = (Account)context.newList[0];
			Account sameAccount = [Select Name FROM Account Where Id=:firstAccount.Id LIMIT 1];
			update sameAccount;
		}
	}
}