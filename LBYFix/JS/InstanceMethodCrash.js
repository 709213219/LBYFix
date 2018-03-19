fixMethod('LBYFixDemo', 'instanceMightCrash:', 1, false,
          function(instance, originInvocation, originArguments) {
          if (originArguments[0] == null) {
          runErrorBranch('LBYFixDemo', 'instanceMightCrash');
          } else {
          runInvocation(originInvocation);
          }
          });
