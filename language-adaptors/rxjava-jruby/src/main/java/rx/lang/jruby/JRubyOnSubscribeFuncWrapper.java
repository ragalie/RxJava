/**
 * Copyright 2013 Netflix, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package rx.lang.jruby;

import org.jruby.RubyProc;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.javasupport.JavaUtil;

import rx.Observable.OnSubscribeFunc;
import rx.Observer;
import rx.Subscription;

/**
 * Concrete wrapper that accepts a {@link RubyProc} and produces a {@link OnSubscribeFunc}.
 *
 * @param <T>
 */
public class JRubyOnSubscribeFuncWrapper<T> implements OnSubscribeFunc<T> {

    private final RubyProc proc;
    private final ThreadContext context;

    public JRubyOnSubscribeFuncWrapper(ThreadContext context, RubyProc proc) {
        this.proc = proc;
        this.context = context;
    }

    @Override
    public Subscription onSubscribe(Observer<? super T> observer) {
        IRubyObject[] array = {JavaUtil.convertJavaToRuby(context.getRuntime(), observer)};
        return (Subscription) proc.call(context, array);
    }

}
